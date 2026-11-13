// The PR stack (gh stack) of the focused space's branch: each PR's approval,
// reviewers, unresolved review threads, comments and CI, plus notifications when
// they change. Without a stack, the branch's own PR.
//
// Two kinds of copy. props { watch: true } (a 0px block in the sidebar, so it runs
// from the start) is the only one that asks GitHub: every space's place, every
// 60s while the window is in front, every 5 min behind it, at once when the
// focused space changes or shared "stack.refresh" is bumped. It keeps results in
// shared "stack.data" (place -> stack) and posts notifications. The panel copy
// only draws "stack.data" for the focused space.

import { View, div, svg } from "gpui-kit";
import { v_flex, h_flex } from "gpui-base";
import { spaces, panes, focused, exec, run, theme, shared, setShared, notify, props, window } from "herdr";

const FRONT = 60000, BEHIND = 300000, NO_REPO = 600000;

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
    this.open = new Set(); // PR numbers expanded in the panel
    if (!this.watch) return;
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
    if (this.busy) return;
    const now = Date.now();
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
          next[k] = { ...result, at: Date.now() };
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
      .on_click((_e, cx) => { cx.stop_propagation(); action(); cx.notify(); })
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

  render() {
    const t = theme();
    if (this.watch) return div();
    const fp = focusedPlace();
    const d = fp ? (shared("stack.data") ?? {})[fp.key] : null;
    const refresh = () => setShared("stack.refresh", Date.now());
    const header = h_flex().h(36).px(14).flex_none().items_center().gap(6).text_size(11.5).text_color(t.dim)
      .child(div().font_medium().child(d?.stacked === false ? "Pull request" : "Stack"))
      .when(Boolean(d?.trunk), (el) => el.child(div().child(`→ ${d.trunk}`)))
      .child(div().flex_1())
      .when(Boolean(d?.at), (el) => el.child(div().child(ago(new Date(d.at).toISOString()))))
      .child(div().id("stack-refresh").px(4).rounded(4).cursor_pointer().hover((s) => s.bg(t.hover).text_color(t.foreground))
        .tooltip("Refresh").on_click(() => refresh()).child("⟳"));
    const message = (text) => div().px(14).pt(4).text_size(12).text_color(t.dim).child(text);
    const body = v_flex().id("stack-list").flex_1().min_h(0).px(6).pb(10).gap(2).overflow_y_scrollbar();
    let content;
    if (!fp) content = body.child(message("No space selected."));
    else if (!d) content = body.child(message("Looking…"));
    else if (d.none === "repo") content = body.child(message("Not a git repository."));
    else if (d.none === "pr") content = body.child(message(`No PR for ${d.branch || "this branch"} yet.`));
    else if (d.error && !d.branches) content = body.child(message(d.error));
    else {
      // gh stack lists trunk-first; the top of the stack reads best at the top.
      const rows = [...d.branches].reverse().map((b) => this.row(fp, b, d.prs[b.pr], t));
      content = body
        .when(Boolean(d.error), (el) => el.child(message(d.error)))
        .children(rows)
        .when(d.stacked !== false, (el) => el.child(h_flex().px(8).pt(10).gap(5)
          .when(d.branches.some((b) => b.rebase), (el) => el.child(div().flex_1().text_size(11).text_color(t.ansi3).child("⚠ needs rebase")))
          .when(!d.branches.some((b) => b.rebase), (el) => el.child(div().flex_1()))
          .child(this.button("st-sync", "Sync", t, () => this.inPane(["gh", "stack", "sync"])))
          .child(this.button("st-rebase", "Rebase", t, () => this.inPane(["gh", "stack", "rebase"])))
          .child(this.button("st-push", "Submit", t, () => this.inPane(["gh", "stack", "submit"])))));
    }
    return v_flex().size_full().min_h(0).bg(t.chrome).text_color(t.foreground).text_size(13).child(header).child(content);
  }
}
