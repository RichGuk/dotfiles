// A GitHub overview in three parts:
// - this space: the PR stack (gh stack) of the focused space's branch, each PR's
//   approval, reviewers, unresolved review threads, comments and CI; without a
//   stack, the branch's own PR; without a PR, a button to make one;
// - your open PRs anywhere with comments from people you haven't answered;
// - PRs waiting on your review, each of which an agent can review first.
// The last two follow the work/personal context (owner zeneducate is work).
//
// Two kinds of copy. props { watch: true } (a 0px block in the sidebar, so it runs
// from the start) is the only one that asks GitHub: every space's place, every
// 60s while the window is in front, every 5 min behind it, at once when the
// focused space changes or shared "stack.refresh" is bumped; and one search for
// the other two parts every 2 min (10 behind). It keeps results in shared
// "stack.data" (place -> stack) and "github.data", and posts notifications. The
// panel copy only draws them.

import { View, div, svg } from "gpui-kit";
import { v_flex, h_flex } from "gpui-base";
import { spaces, panes, focused, exec, run, theme, shared, setShared, notify, props, window } from "herdr";

const FRONT = 60000, BEHIND = 300000, NO_REPO = 600000;
const GH_FRONT = 120000, GH_BEHIND = 600000;
// Your PRs untouched this long aren't waiting on you; review requests this old fold away.
const STALE = 60 * 86400000, OLD = 30 * 86400000;
const WORK_ORGS = ["zeneducate"];
// Where a review agent runs: work repos on this machine, under ~/Dev/Work there.
const WORK_MACHINE = "atlantis";

const ctxOf = (repo) => (WORK_ORGS.includes(repo.split("/")[0].toLowerCase()) ? "work" : "personal");
const shownCtx = (repo) => {
  const a = shared("space.context.active") ?? "all";
  return a === "all" || ctxOf(repo) === a;
};

const GITHUB = `query { viewer { login }
  mine: search(query: "is:pr is:open author:@me archived:false", type: ISSUE, first: 40) { nodes { ... on PullRequest {
    number title url isDraft updatedAt repository { nameWithOwner }
    reviewThreads(first: 100) { nodes { isResolved path comments(last: 1) { nodes { author { login __typename } body createdAt url } } } }
    comments(last: 10) { nodes { author { login __typename } body createdAt url } } } } }
  asked: search(query: "is:pr is:open review-requested:@me archived:false", type: ISSUE, first: 40) { nodes { ... on PullRequest {
    number title url isDraft updatedAt author { login } repository { nameWithOwner } } } } }`;

// What a person (not a bot) said on your PR that you haven't answered: unresolved
// threads they spoke last in, and conversation comments since your last one.
function unanswered(p, viewer) {
  const person = (c) => c?.author && c.author.__typename !== "Bot";
  const said = (c, path) => ({ path, author: c.author.login, body: c.body, url: c.url, at: c.createdAt });
  const threads = p.reviewThreads.nodes.filter((t) => !t.isResolved)
    .map((t) => [t, t.comments.nodes[0]]).filter(([, c]) => person(c) && c.author.login !== viewer)
    .map(([t, c]) => said(c, t.path));
  const talk = p.comments.nodes.filter(person);
  const since = talk.slice(talk.findLastIndex((c) => c.author.login === viewer) + 1).map((c) => said(c));
  return [...threads, ...since];
}

// Where a space is now: its first terminal's live folder, else where it was made.
function place(s, ps) {
  const tabs = new Set((s.tabs ?? []).map((t) => t.id));
  return ps.find((p) => tabs.has(p.tab) && p.cwd)?.cwd || s.folder;
}
const keyOf = (machine, cwd) => JSON.stringify([machine ?? null, cwd]);

// The focused space's place: the focused terminal's folder when it's in that space.
function focusedPlace() {
  const f = focused();
  const s = spaces().find((s) => s.id === f?.space) ?? spaces().find((s) => s.active);
  if (!s) return null;
  const ps = panes();
  const inSpace = ps.some((p) => p.pane === f?.pane && s.tabs.some((t) => t.id === p.tab));
  const cwd = (inSpace && f?.cwd) || place(s, ps);
  return cwd ? { space: s, machine: s.machine ?? null, cwd, key: keyOf(s.machine, cwd) } : null;
}

const PR_FIELDS = `number title url state isDraft reviewDecision
  latestOpinionatedReviews(first: 20) { nodes { author { login } state } }
  reviewRequests(first: 10) { nodes { requestedReviewer { ... on User { login } ... on Team { name } } } }
  reviewThreads(first: 100) { nodes { isResolved path comments(last: 1) { totalCount nodes { author { login } body createdAt url } } } }
  comments(last: 3) { totalCount nodes { author { login } body createdAt url } }
  commits(last: 1) { nodes { commit { statusCheckRollup { state } } } }`;

// The parts of a PR the panel and the notifications use.
function shape(p, viewer) {
  const threads = p.reviewThreads.nodes.filter((t) => !t.isResolved).map((t) => {
    const c = t.comments.nodes[0];
    return { path: t.path, author: c?.author?.login ?? "?", body: c?.body ?? "", url: c?.url, at: c?.createdAt };
  });
  const latest = [...p.reviewThreads.nodes.map((t) => t.comments.nodes[0]), ...p.comments.nodes]
    .filter((c) => c && c.author?.login !== viewer)
    .map((c) => c.createdAt).sort().at(-1) ?? null;
  return {
    number: p.number, title: p.title, url: p.url, state: p.state, draft: p.isDraft,
    decision: p.reviewDecision,
    reviews: p.latestOpinionatedReviews.nodes.map((r) => ({ login: r.author?.login ?? "?", state: r.state })),
    requested: p.reviewRequests.nodes.map((r) => r.requestedReviewer?.login ?? r.requestedReviewer?.name).filter(Boolean),
    threads,
    comments: p.comments.nodes.map((c) => ({ author: c.author?.login ?? "?", body: c.body, url: c.url, at: c.createdAt })),
    commentCount: p.comments.totalCount,
    latestOther: latest,
    ci: p.commits.nodes[0]?.commit?.statusCheckRollup?.state ?? null,
  };
}

const short = (s, n) => {
  s = (s ?? "").replace(/\s+/g, " ").trim();
  return s.length > n ? `${s.slice(0, n - 1)}…` : s;
};

function ago(iso) {
  if (!iso) return "";
  const s = (Date.now() - Date.parse(iso)) / 1000;
  if (s < 60) return "now";
  if (s < 3600) return `${Math.floor(s / 60)}m`;
  if (s < 86400) return `${Math.floor(s / 3600)}h`;
  return `${Math.floor(s / 86400)}d`;
}

export default class Stack extends View {
  init(_props, cx) {
    this.watch = Boolean(props()?.watch);
    this.open = new Set(); // PR numbers (and other PRs' urls) expanded in the panel
    this.showOld = false;
    if (!this.watch) return;
    this.ghLast = 0;
    this.ghBusy = false;
    this.seenGhRefresh = shared("stack.refresh") ?? 0;
    // Review requests already told about (null: first run, tell nothing).
    this.asked = JSON.parse(localStorage.getItem("asked") ?? "null");
    this.last = {}; // place -> when it was last asked
    this.busy = false;
    this.seenRefresh = shared("stack.refresh") ?? 0;
    this.seenFocus = null;
    // What notifications compare against, per PR url; kept so a restart doesn't
    // announce everything again.
    this.known = JSON.parse(localStorage.getItem("known") ?? "{}");
    cx.timer.every(1000, (cx) => this.tick(cx));
  }

  tick(cx) {
    const now = Date.now();
    const bumped = shared("stack.refresh") ?? 0;
    if (bumped !== this.seenGhRefresh) { this.seenGhRefresh = bumped; this.ghLast = 0; }
    if (!this.ghBusy && now - this.ghLast > (window()?.active ? GH_FRONT : GH_BEHIND)) this.github(cx);
    if (this.busy) return;
    const fp = focusedPlace();
    const refresh = shared("stack.refresh") ?? 0;
    const urgent = new Set();
    if (fp && fp.key !== this.seenFocus) { this.seenFocus = fp.key; urgent.add(fp.key); }
    if (refresh !== this.seenRefresh) { this.seenRefresh = refresh; if (fp) urgent.add(fp.key); }
    const every = window()?.active ? FRONT : BEHIND;
    const data = shared("stack.data") ?? {};
    const ps = panes();
    const places = new Map();
    for (const s of spaces()) {
      const cwd = place(s, ps);
      if (cwd) places.set(keyOf(s.machine, cwd), { machine: s.machine ?? null, cwd, space: s.id });
    }
    if (fp) places.set(fp.key, { machine: fp.machine, cwd: fp.cwd, space: fp.space.id });
    const due = [...places].filter(([k]) => urgent.has(k)
      || now - (this.last[k] ?? 0) > (data[k]?.none === "repo" ? NO_REPO : every));
    if (!due.length) return;
    this.busy = true;
    cx.spawn(async (cx) => {
      try {
        for (const [k, p] of due) {
          this.last[k] = Date.now();
          const result = await this.fetch(p);
          const next = { ...(shared("stack.data") ?? {}) };
          // Keep only places some space is at now.
          for (const old of Object.keys(next)) if (!places.has(old)) delete next[old];
          next[k] = { ...result, at: Date.now(), space: p.space };
          setShared("stack.data", next);
          if (result.prs) this.announce(result, p.space);
        }
        localStorage.setItem("known", JSON.stringify(this.known));
      } finally {
        this.busy = false;
        cx.notify();
      }
    });
  }

  // One place: its stack's branches (or its branch's PR), then GitHub for the PRs.
  async fetch({ machine, cwd }) {
    const opt = { cwd, on: machine, timeout: 30000 };
    let branches, trunk = null, stacked = true;
    try {
      const r = await exec("gh", ["stack", "view", "--json"], opt);
      if (r.code === 0) {
        const s = JSON.parse(r.stdout);
        trunk = s.trunk;
        branches = s.branches.map((b) => ({ name: b.name, current: b.isCurrent, merged: b.isMerged, queued: b.isQueued, rebase: b.needsRebase, pr: b.pr?.number ?? null, url: b.pr?.url ?? null }));
      } else {
        const err = r.stderr + r.stdout;
        if (/not a git repository/i.test(err)) return { none: "repo" };
        stacked = false;
        const pr = await exec("gh", ["pr", "view", "--json", "number,url,headRefName,baseRefName"], opt);
        if (pr.code !== 0) {
          const b = await exec("git", ["branch", "--show-current"], opt);
          if (b.code !== 0) return { none: "repo" };
          return { none: "pr", branch: b.stdout.trim() };
        }
        const p = JSON.parse(pr.stdout);
        trunk = p.baseRefName;
        branches = [{ name: p.headRefName, current: true, merged: false, queued: false, rebase: false, pr: p.number, url: p.url }];
      }
    } catch (e) {
      return { error: String(e.message ?? e) };
    }
    const withPr = branches.filter((b) => b.url);
    if (!withPr.length) return { stacked, trunk, branches, prs: {} };
    // One query per repo (a stack is one repo; aliases keep PRs apart).
    const [, owner, name] = withPr[0].url.match(/github\.com\/([^/]+)\/([^/]+)\//) ?? [];
    const query = `query { viewer { login } repository(owner: ${JSON.stringify(owner)}, name: ${JSON.stringify(name)}) {
      ${withPr.map((b) => `p${b.pr}: pullRequest(number: ${b.pr}) { ${PR_FIELDS} }`).join("\n")} } }`;
    try {
      const r = await exec("gh", ["api", "graphql", "-f", `query=${query}`], opt);
      const d = JSON.parse(r.stdout);
      if (!d.data) return { stacked, trunk, branches, prs: {}, error: d.errors?.[0]?.message ?? r.stderr.trim() };
      const viewer = d.data.viewer.login;
      const prs = {};
      for (const [k, p] of Object.entries(d.data.repository)) if (p) prs[k.slice(1)] = shape(p, viewer);
      return { stacked, trunk, branches, prs, viewer };
    } catch (e) {
      return { stacked, trunk, branches, prs: {}, error: String(e.message ?? e) };
    }
  }

  // Your PRs needing a reply and PRs waiting on your review, in one search.
  github(cx) {
    this.ghBusy = true;
    this.ghLast = Date.now();
    cx.spawn(async (cx) => {
      try {
        const r = await exec("gh", ["api", "graphql", "-f", `query=${GITHUB}`], { timeout: 30000 });
        const d = JSON.parse(r.stdout || "{}").data;
        if (!d) throw new Error(r.stderr.trim() || "GitHub search failed");
        const viewer = d.viewer.login;
        const base = (p) => ({ number: p.number, title: p.title, url: p.url, draft: p.isDraft, repo: p.repository.nameWithOwner, at: p.updatedAt });
        const mine = d.mine.nodes.filter((p) => p?.number && Date.now() - Date.parse(p.updatedAt) < STALE)
          .map((p) => ({ ...base(p), waiting: unanswered(p, viewer) })).filter((p) => p.waiting.length);
        const asked = d.asked.nodes.filter((p) => p?.number).map((p) => ({ ...base(p), author: p.author?.login ?? "?" }));
        this.announceAsked(asked);
        setShared("github.data", { viewer, mine, asked, at: Date.now() });
      } catch (e) {
        setShared("github.data", { ...(shared("github.data") ?? {}), error: String(e.message ?? e), at: Date.now() });
      } finally {
        this.ghBusy = false;
        cx.notify();
      }
    });
  }

  announceAsked(asked) {
    const first = this.asked === null;
    const known = new Set(this.asked ?? []);
    for (const p of asked) {
      if (first || known.has(p.url) || p.draft || !shownCtx(p.repo)) continue;
      notify({ title: `Review requested · #${p.number}`, body: `${p.author}: ${short(p.title, 60)}`, level: "info",
        action: { name: "layout.select", args: { stack: "panel-body", child: "stack" } } });
    }
    // Only open requests are kept, so one asked again later is told again.
    this.asked = asked.map((p) => p.url);
    localStorage.setItem("asked", JSON.stringify(this.asked));
  }

  // A new space where the repo lives (work: on WORK_MACHINE) with Claude reviewing the PR.
  async reviewAgent(p) {
    const work = ctxOf(p.repo) === "work";
    const on = work ? WORK_MACHINE : undefined;
    const name = p.repo.split("/")[1];
    const r = await exec("sh", ["-c", 'cd "$HOME/Dev/$1/$2" 2>/dev/null && pwd', "sh", work ? "Work" : "Personal", name], { on }).catch(() => null);
    const folder = r?.code === 0 ? r.stdout.trim() : "";
    run("space.new", {
      name: `review #${p.number}`, machine: on ?? "", argv: ["claude"], ...(folder ? { folder } : {}),
      task: `Review PR #${p.number} in ${p.repo} (${p.url}) by ${p.author}: "${p.title}". `
        + `Read it with gh (gh pr view ${p.number} -R ${p.repo} --comments, gh pr diff ${p.number} -R ${p.repo}); `
        + `don't check it out or change files here, but read the surrounding code where it helps. `
        + `Give me a short summary, then bugs and risks with file:line, then questions for the author. `
        + `Don't post anything to GitHub unless I ask.`,
    });
  }

  // The space whose stack has this PR, with where it is.
  spaceWith(url) {
    for (const [k, d] of Object.entries(shared("stack.data") ?? {})) {
      if (d.space && Object.values(d.prs ?? {}).some((p) => p.url === url)) return { id: d.space, cwd: JSON.parse(k)[1], d };
    }
    return null;
  }

  // Compare each PR with what was known; tell the person what changed.
  announce(result, space) {
    const action = { name: "space.select", args: { id: space } };
    for (const b of result.branches) {
      const p = result.prs[b.pr];
      if (!p) continue;
      const was = this.known[p.url];
      const now = {
        reviews: Object.fromEntries(p.reviews.map((r) => [r.login, r.state])),
        latestOther: p.latestOther, ci: p.ci, state: p.state, rebase: b.rebase,
      };
      this.known[p.url] = now;
      if (!was) continue; // first sight: nothing to compare
      const title = `#${p.number} ${short(p.title, 40)}`;
      for (const [who, state] of Object.entries(now.reviews)) {
        if (was.reviews?.[who] === state || who === result.viewer) continue;
        if (state === "APPROVED") notify({ title, body: `Approved by ${who}`, level: "success", action });
        else if (state === "CHANGES_REQUESTED") notify({ title, body: `${who} requested changes`, level: "warning", action });
      }
      if (now.latestOther && now.latestOther !== was.latestOther && (!was.latestOther || now.latestOther > was.latestOther)) {
        const fresh = [...p.threads, ...p.comments].filter((c) => c.at && (!was.latestOther || c.at > was.latestOther) && c.author !== result.viewer);
        const who = [...new Set(fresh.map((c) => c.author))].join(", ");
        notify({ title, body: who ? `New comments from ${who}` : "New comments", level: "info", action });
      }
      if (now.ci !== was.ci && (now.ci === "FAILURE" || now.ci === "ERROR")) notify({ title, body: "CI failed", level: "error", action });
      if (now.state === "MERGED" && was.state !== "MERGED") notify({ title, body: "Merged", level: "success", action });
      if (now.rebase && !was.rebase) notify({ title, body: "Needs rebase (gh stack rebase)", level: "warning", action });
    }
  }

  // A command in a new pane under the focused one, so its output (and prompts) show.
  inPane(argv) {
    run("pane.split", { direction: "down", argv });
  }

  openUrl(url) {
    exec(window()?.platform === "macos" ? "open" : "xdg-open", [url]).catch(() => {});
  }

  askAgent(fp, b, p) {
    run("tab.new", {
      space: fp.space.id, folder: fp.cwd, name: `#${p.number} review`, argv: ["claude"],
      task: `Address the unresolved review comments on PR #${p.number} (${p.url}), branch ${b.name}. `
        + `Read them with gh (gh pr view ${p.number} --comments, and the review threads via gh api), `
        + `make the changes on that branch, and summarise what you changed and anything you disagree with.`,
    });
  }

  badge(text, color, t) {
    return div().flex_none().px(5).h(17).rounded(4).flex().items_center().text_size(10.5).text_color(color).bg(t.surface).child(text);
  }

  review(p, t) {
    if (p.state === "MERGED") return this.badge("Merged", t.ansi5, t);
    if (p.state === "CLOSED") return this.badge("Closed", t.dim, t);
    if (p.draft) return this.badge("Draft", t.dim, t);
    if (p.decision === "APPROVED") return this.badge("✓ Approved", t.ansi2, t);
    if (p.decision === "CHANGES_REQUESTED") return this.badge("● Changes", t.ansi1, t);
    return this.badge(p.requested.length ? "Review requested" : "No review", t.ansi3, t);
  }

  ci(p, t) {
    if (!p.ci) return null;
    const [glyph, color] = { SUCCESS: ["✓", t.ansi2], FAILURE: ["✗", t.ansi1], ERROR: ["✗", t.ansi1], PENDING: ["…", t.ansi3], EXPECTED: ["…", t.ansi3] }[p.ci] ?? ["?", t.dim];
    return div().flex_none().text_size(11).text_color(color).tooltip(`CI ${p.ci.toLowerCase()}`).child(`${glyph} CI`);
  }

  button(id, label, t, action) {
    return div().id(id).flex_none().px(7).h(22).rounded(5).flex().items_center().text_size(11)
      .text_color(t.muted).bg(t.surface).cursor_pointer().hover((s) => s.bg(t.hover).text_color(t.foreground))
      .on_click((_e, cx) => { cx.stop_propagation(); action(cx); cx.notify(); })
      .child(label);
  }

  row(fp, b, p, t) {
    const open = this.open.has(b.pr);
    const glyph = b.merged ? "✓" : b.queued ? "◎" : b.rebase ? "⚠" : "○";
    const head = h_flex().id(`pr-${b.name}`).px(8).py(5).gap(7).items_start().rounded(7)
      .when(b.current, (el) => el.bg(t.selected))
      .hover((s) => s.bg(t.hover)).cursor_pointer()
      .on_click((_e, cx) => { open ? this.open.delete(b.pr) : this.open.add(b.pr); cx.notify(); })
      .child(div().flex_none().w(12).pt(1).text_size(12).text_color(b.rebase ? t.ansi3 : t.dim).child(glyph))
      .child(v_flex().flex_1().min_w(0).gap(3)
        .child(h_flex().gap(6).items_center()
          .child(div().flex_none().text_size(12).text_color(t.dim).child(b.pr ? `#${b.pr}` : "no PR"))
          .child(div().flex_1().min_w(0).truncate().text_size(12.5).text_color(t.foreground).child(p?.title ?? b.name)))
        .when(Boolean(p), (el) => el.child(h_flex().gap(6).items_center().flex_wrap()
          .child(this.review(p, t))
          .child(this.ci(p, t) ?? div())
          .when(p.threads.length > 0, (el) => el.child(div().text_size(11).text_color(t.ansi3).tooltip("Unresolved review threads").child(`💬 ${p.threads.length}`)))
          .when(p.commentCount > 0, (el) => el.child(div().text_size(11).text_color(t.dim).tooltip("Conversation comments").child(`✎ ${p.commentCount}`)))
          .child(div().flex_1())
          .child(div().text_size(10.5).text_color(t.dim).truncate()
            .child(p.reviews.map((r) => `${r.login} ${r.state === "APPROVED" ? "✓" : r.state === "CHANGES_REQUESTED" ? "●" : "·"}`).join("  "))))));
    if (!open || !p) return head;
    const quote = (c, i) => v_flex().id(`c-${b.pr}-${i}`).px(8).py(5).gap(2).rounded(6).bg(t.surface).cursor_pointer()
      .hover((s) => s.bg(t.hover))
      .on_click((_e, cx) => { cx.stop_propagation(); if (c.url) this.openUrl(c.url); })
      .child(h_flex().gap(6).text_size(10.5).text_color(t.dim)
        .child(div().text_color(t.muted).child(c.author))
        .when(Boolean(c.path), (el) => el.child(div().min_w(0).truncate().child(c.path)))
        .child(div().flex_1())
        .child(ago(c.at)))
      .child(div().text_size(11.5).text_color(t.foreground).child(short(c.body, 220)));
    return v_flex().gap(4)
      .child(head)
      .child(v_flex().pl(27).pr(8).pb(6).gap(5)
        .when(p.requested.length > 0, (el) => el.child(div().text_size(11).text_color(t.dim).child(`Waiting on ${p.requested.join(", ")}`)))
        .when(p.threads.length > 0, (el) => el.child(div().text_size(11).text_color(t.dim).child("Unresolved threads")).children(p.threads.map(quote)))
        .when(p.comments.length > 0, (el) => el.child(div().text_size(11).text_color(t.dim).child("Latest comments")).children(p.comments.slice(-2).map((c, i) => quote(c, `x${i}`))))
        .child(h_flex().gap(5).flex_wrap()
          .when(p.threads.length > 0 || p.decision === "CHANGES_REQUESTED", (el) => el.child(this.button(`ask-${b.pr}`, "↗ Ask agent to address", t, () => this.askAgent(fp, b, p))))
          .child(this.button(`gh-${b.pr}`, "Open on GitHub", t, () => this.openUrl(p.url)))
          .when(!b.current, (el) => el.child(this.button(`co-${b.pr}`, "Check out", t, () => this.inPane(["gh", "stack", "checkout", String(b.pr)]))))));
  }

  section(t, id, title, extra) {
    return h_flex().id(id).px(8).pt(14).pb(4).gap(6).items_center().text_size(11).text_color(t.dim)
      .child(div().font_medium().text_color(t.muted).child(title))
      .when(Boolean(extra), (el) => el.child(div().child(extra)));
  }

  // One PR not in this space: your PR with comments waiting, or one asking for your review.
  other(p, t, kind) {
    const key = `${kind}-${p.url}`;
    const open = this.open.has(key);
    const home = kind === "mine" ? this.spaceWith(p.url) : null;
    const sub = kind === "mine"
      ? `💬 ${p.waiting.length} from ${[...new Set(p.waiting.map((c) => c.author))].join(", ")}`
      : `${p.author}${p.draft ? " · draft" : ""}`;
    const head = h_flex().id(key).px(8).py(5).gap(7).items_start().rounded(7)
      .hover((s) => s.bg(t.hover)).cursor_pointer()
      .on_click((_e, cx) => { open ? this.open.delete(key) : this.open.add(key); cx.notify(); })
      .child(v_flex().flex_1().min_w(0).gap(3)
        .child(h_flex().gap(6).items_center()
          .child(div().flex_none().text_size(12).text_color(t.dim).child(`#${p.number}`))
          .child(div().flex_1().min_w(0).truncate().text_size(12.5).text_color(p.draft ? t.muted : t.foreground).child(p.title)))
        .child(h_flex().gap(6).text_size(11).text_color(t.dim)
          .child(div().flex_none().child(p.repo.split("/")[1]))
          .child(div().flex_1().min_w(0).truncate().text_color(kind === "mine" ? t.ansi3 : t.dim).child(sub))
          .child(div().flex_none().child(ago(p.at)))));
    if (!open) return head;
    const quote = (c, i) => v_flex().id(`${key}-${i}`).px(8).py(5).gap(2).rounded(6).bg(t.surface).cursor_pointer()
      .hover((s) => s.bg(t.hover))
      .on_click((_e, cx) => { cx.stop_propagation(); if (c.url) this.openUrl(c.url); })
      .child(h_flex().gap(6).text_size(10.5).text_color(t.dim)
        .child(div().text_color(t.muted).child(c.author))
        .when(Boolean(c.path), (el) => el.child(div().min_w(0).truncate().child(c.path)))
        .child(div().flex_1())
        .child(ago(c.at)))
      .child(div().text_size(11.5).text_color(t.foreground).child(short(c.body, 220)));
    const branch = home && Object.values(home.d.branches ?? []).find((b) => home.d.prs[b.pr]?.url === p.url);
    return v_flex().gap(4)
      .child(head)
      .child(v_flex().pl(8).pr(8).pb(6).gap(5)
        .when(kind === "mine", (el) => el.children(p.waiting.map(quote)))
        .child(h_flex().gap(5).flex_wrap()
          .when(kind === "asked", (el) => el.child(this.button(`rv-${key}`, "↗ Review with agent", t, (cx) => cx.spawn(async () => this.reviewAgent(p)))))
          .when(Boolean(home && branch), (el) => el.child(this.button(`ask-${key}`, "↗ Ask agent to address", t,
            () => this.askAgent({ space: { id: home.id }, cwd: home.cwd }, branch, home.d.prs[branch.pr]))))
          .when(Boolean(home), (el) => el.child(this.button(`go-${key}`, "Go to space", t, () => run("space.select", { id: home.id }))))
          .child(this.button(`gh-${key}`, "Open on GitHub", t, () => this.openUrl(p.url)))));
  }

  // The focused space's stack, or its PR, or a way to make one.
  here(fp, d, t, message) {
    if (!fp) return [message("No space selected.")];
    if (!d) return [message("Looking…")];
    if (d.none === "repo") return [message("Not a git repository.")];
    if (d.none === "pr") return [message(`No PR for ${d.branch || "this branch"} yet.`),
      h_flex().px(8).pt(6).child(this.button("pr-create", "Create PR", t, () => this.inPane(["gh", "pr", "create"])))];
    if (d.error && !d.branches) return [message(d.error)];
    const rows = [];
    if (d.error) rows.push(message(d.error));
    // gh stack lists trunk-first; the top of the stack reads best at the top.
    rows.push(...[...d.branches].reverse().map((b) => this.row(fp, b, d.prs[b.pr], t)));
    if (d.stacked !== false) rows.push(h_flex().px(8).pt(10).gap(5)
      .child(div().flex_1().text_size(11).text_color(t.ansi3).child(d.branches.some((b) => b.rebase) ? "⚠ needs rebase" : ""))
      .child(this.button("st-sync", "Sync", t, () => this.inPane(["gh", "stack", "sync"])))
      .child(this.button("st-rebase", "Rebase", t, () => this.inPane(["gh", "stack", "rebase"])))
      .child(this.button("st-push", "Submit", t, () => this.inPane(["gh", "stack", "submit"]))));
    return rows;
  }

  render() {
    const t = theme();
    if (this.watch) return div();
    const fp = focusedPlace();
    const d = fp ? (shared("stack.data") ?? {})[fp.key] : null;
    const g = shared("github.data") ?? {};
    const refresh = () => setShared("stack.refresh", Date.now());
    const header = h_flex().h(36).px(14).flex_none().items_center().gap(6).text_size(11.5).text_color(t.dim)
      .child(div().font_medium().child("GitHub"))
      .child(div().flex_1())
      .when(Boolean(d?.at ?? g.at), (el) => el.child(div().child(ago(new Date(d?.at ?? g.at).toISOString()))))
      .child(div().id("stack-refresh").px(4).rounded(4).cursor_pointer().hover((s) => s.bg(t.hover).text_color(t.foreground))
        .tooltip("Refresh").on_click(() => refresh()).child("⟳"));
    const message = (text) => div().px(14).pt(4).text_size(12).text_color(t.dim).child(text);
    const mine = (g.mine ?? []).filter((p) => shownCtx(p.repo));
    const asked = (g.asked ?? []).filter((p) => shownCtx(p.repo));
    const fresh = asked.filter((p) => Date.now() - Date.parse(p.at) < OLD);
    const old = asked.filter((p) => Date.now() - Date.parse(p.at) >= OLD);
    const where = d?.stacked === false ? "Pull request" : d?.branches ? "Stack" : "This space";
    const body = v_flex().id("stack-list").flex_1().min_h(0).px(6).pb(10).gap(2).overflow_y_scrollbar()
      .child(this.section(t, "s-here", where, d?.trunk ? `→ ${d.trunk}` : null).pt(2))
      .children(this.here(fp, d, t, message))
      .when(Boolean(g.error), (el) => el.child(message(g.error)))
      .child(this.section(t, "s-mine", "Needs your reply", mine.length ? String(mine.length) : null))
      .when(!g.at, (el) => el.child(message("Looking…")))
      .when(Boolean(g.at) && !mine.length, (el) => el.child(message("Nothing waiting.")))
      .children(mine.map((p) => this.other(p, t, "mine")))
      .child(this.section(t, "s-asked", "Waiting on your review", asked.length ? String(asked.length) : null))
      .when(Boolean(g.at) && !asked.length, (el) => el.child(message("Nothing waiting.")))
      .children(fresh.map((p) => this.other(p, t, "asked")))
      .when(old.length > 0, (el) => el.child(div().id("s-old").px(8).py(4).text_size(11).text_color(t.dim).cursor_pointer()
        .hover((s) => s.text_color(t.foreground))
        .on_click((_e, cx) => { this.showOld = !this.showOld; cx.notify(); })
        .child(`${this.showOld ? "▾" : "▸"} ${old.length} older than 30 days`)))
      .when(this.showOld, (el) => el.children(old.map((p) => this.other(p, t, "asked"))));
    return v_flex().size_full().min_h(0).bg(t.chrome).text_color(t.foreground).text_size(13).child(header).child(body);
  }
}
