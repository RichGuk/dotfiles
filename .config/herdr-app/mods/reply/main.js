// reply: answer an agent without going to it. Opened as a dialog with props
// { terminal, name } (agents-ctx's ↩ on a row, or its reply key). Shows the end
// of the agent's screen, then:
// - a menu on screen (Claude's permission prompts: "❯ 1. Yes"): a button per
//   choice, which presses that number, and Esc;
// - otherwise quick replies and a box to type one, sent with Enter.

import { View, div } from "gpui-kit";
import { v_flex, h_flex, InputState, Input } from "gpui-base";
import { hc, props, closeOverlay, theme, agents } from "herdr";

const REPLIES = ["Continue", "Yes, go ahead", "Commit and push", "Fix it"];
// One choice of a menu, once box edges are gone: "❯ 1. Yes", "  2. No, and tell Claude…".
const OPTION = /^\s*(?:[❯>›]\s*)?(\d)\.\s+(.+?)\s*$/;
const SCREEN = 12;

export default class Reply extends View {
  init(_props, cx) {
    this.lines = null;
    this.options = [];
    this.busy = false;
    this.input = InputState.new({ placeholder: "Reply…" });
    this.input.on("submit", (_e, cx) => { const text = this.input.value().trim(); if (text) this.send(text, cx); });
    this.input.focus();
    cx.timer.after(300, () => this.input.focus());
    cx.spawn(async (cx) => {
      const r = await hc(["read", props().terminal]).catch(() => null);
      const all = (r?.stdout ?? "").split("\n").map((l) => l.replace(/[│┃]/g, " ").trimEnd());
      while (all.length && !all.at(-1).trim()) all.pop();
      this.lines = all.slice(-SCREEN);
      // Only a menu still at the bottom of the screen is the question being asked.
      if (this.blocked()) {
        const seen = new Set();
        this.options = all.slice(-20).map((l) => OPTION.exec(l)).filter(Boolean)
          .map((m) => ({ key: m[1], label: m[2] })).filter((o) => !seen.has(o.key) && seen.add(o.key));
      }
      cx.notify();
    });
  }

  blocked() {
    return agents().find((a) => a.address === props().terminal)?.status === "blocked";
  }

  // Typed text answers a blocked agent too (a question in words), so it's forced then.
  send(text, cx) {
    this.run(["send", props().terminal, text, ...(this.blocked() ? ["--force"] : [])], cx);
  }

  press(key, cx) {
    this.run(["keys", props().terminal, key], cx);
  }

  run(args, cx) {
    if (this.busy) return;
    this.busy = true;
    cx.notify();
    cx.spawn(async () => {
      await hc(args).catch(() => null);
      closeOverlay(props().overlay);
    });
  }

  button(t, id, label, action, strong = false) {
    return div().id(id).h(28).px(10).flex().items_center().rounded(7).flex_none().max_w_full()
      .text_size(12).truncate().cursor_pointer()
      .bg(strong ? t.solid : t.raised).text_color(strong ? t.solid_foreground : t.foreground)
      .hover((s) => s.bg(strong ? t.accent : t.hover))
      .on_click((_e, cx) => action(cx))
      .child(label);
  }

  render() {
    const t = theme();
    const p = props() ?? {};
    const menu = this.options.length > 0;
    return v_flex().id("reply").size_full().p(14).gap(10).bg(t.popover).text_color(t.foreground)
      .child(h_flex().gap(8).items_center()
        .child(div().flex_1().truncate().font_semibold().text_size(13).child(p.name || p.terminal || "Agent"))
        .when(this.busy, (el) => el.child(div().text_size(11).text_color(t.dim).child("Sending…"))))
      .child(v_flex().flex_1().min_h(0).px(10).py(8).rounded(8).bg(t.background).overflow_hidden()
        .text_size(11).text_color(t.muted)
        .when(this.lines === null, (el) => el.child(div().text_color(t.dim).child("Reading…")))
        .children((this.lines ?? []).map((l, i) => div().id(`l${i}`).h(15).truncate().child(l || " "))))
      .when(menu, (el) => el.child(v_flex().gap(5)
        .children(this.options.map((o, i) => this.button(t, `opt-${o.key}`, `${o.key}  ${o.label}`, (cx) => this.press(o.key, cx), i === 0)))
        .child(this.button(t, "opt-esc", "Esc", (cx) => this.press("esc", cx)))))
      .when(!menu, (el) => el
        .child(h_flex().gap(6).flex_wrap()
          .children(REPLIES.map((r, i) => this.button(t, `r${i}`, r, (cx) => this.send(r, cx)))))
        .child(Input.new(this.input).h(32).px(10).rounded(8).border_1().border_color(t.accent)
          .bg(t.background).text_size(12.5).text_color(t.foreground)));
  }
}
