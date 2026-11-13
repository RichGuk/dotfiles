// How notifications look. Anything can post one with notify({ title, body,
// level, icon, action }); replace this mod to restyle them all. Click to
// run its action (e.g. go to the agent) and dismiss it.

import { View, div, image } from "gpui-kit";
import { v_flex, h_flex } from "gpui-base";
import { props, closeOverlay, run, theme, shared, agents, terminals, panes, spaces } from "herdr";

// toast-ctx: drops a notification whose space is tagged with the context not
// shown (spaces-ctx's "space.context" / "space.context.active"), so a Personal
// agent or PR never pops up while Work shows. Untagged spaces, and notices
// that name no space, always show.

const DOT = { error: "blocked", warning: "working", success: "done", info: "accent" };

// The space a notification's action leads to, if it names one.
function spaceOf(action) {
  const a = action?.args ?? {};
  if (a.space) return a.space;
  if (action?.name === "space.select" && a.id) return a.id;
  if (a.terminal) {
    const found = agents().find((x) => x.address === a.terminal) ?? terminals().find((x) => x.address === a.terminal);
    if (found?.space) return found.space;
  }
  const tab = a.tab ?? (a.pane ? panes().find((x) => x.pane === a.pane)?.tab : null)
    ?? (a.terminal ? panes().find((x) => x.terminal === a.terminal)?.tab : null);
  return tab ? spaces().find((s) => s.tabs.some((t) => t.id === tab))?.id ?? null : null;
}

function muted(p) {
  const showing = shared("space.context.active") ?? "all";
  if (showing === "all") return false;
  const ctx = (shared("space.context") ?? {})[spaceOf(p.action)];
  return Boolean(ctx) && ctx !== showing;
}

export default class Toast extends View {
  init() {
    const p = props() ?? {};
    this.muted = muted(p);
    if (this.muted) closeOverlay(p.overlay);
  }

  render(cx) {
    const t = theme();
    const p = props() ?? {};
    if (this.muted) return div();
    const login = /^([a-z0-9][a-z0-9_.-]{0,31}) needs login; run hc machine login \1$/.exec(p.body ?? "");
    const command = login ? `hc machine login ${login[1]}` : null;
    return h_flex()
      .id("toast")
      .size_full()
      .px(18)
      .gap(12)
      .items_center()
      .bg(t.popover)
      .cursor_pointer()
      .hover((s) => s.bg(t.hover))
      .on_click(() => {
        if (p.action?.name) run(p.action.name, p.action.args ?? {});
        closeOverlay(p.overlay);
      })
      .child(p.icon ? image(p.icon).w(18).h(18).flex_none() : div().size(8).rounded(4).flex_none().bg(t[DOT[p.level] ?? "accent"]))
      .child(
        v_flex()
          .flex_1()
          .overflow_hidden()
          .child(div().truncate().font_semibold().text_size(13).text_color(t.foreground).child(login ? `${login[1]} needs a login: run` : p.title ?? ""))
          .when(!login && Boolean(p.body), (el) => el.child(div().truncate().text_size(12).text_color(t.muted).child(p.body ?? "")))
          .when(Boolean(login), (el) => el.child(h_flex().gap(8).items_center()
            .child(div().flex_1().min_w(0).truncate().tooltip(command).text_size(12).text_color(t.muted).child(command))
            .child(div().id("toast-login-copy").flex_none().px(6).py(3).rounded(4).bg(t.raised)
              .text_size(12).text_color(t.foreground).cursor_pointer().hover(s => s.bg(t.hover))
              .on_click((_e, cx) => { cx.stop_propagation(); cx.write_to_clipboard(command); this.copied = true; cx.notify(); })
              .child(this.copied ? "Copied" : "Copy")))),
      );
  }
}
