// One todo list, each todo Work, Personal or untagged, following spaces-ctx's
// context (shared "space.context.active"): untagged todos show everywhere, new
// ones take the shown context. Kept in shared "todos". Enter adds, click the box
// to tick off, drag to reorder, the arrow starts Claude in a new tab with the todo
// as its task. Opened as a dialog with props { add: true }, it's just the add box
// (tabs-ctx's todo-add key).

import { View, div, svg } from "gpui-kit";
import { v_flex, h_flex, InputState, Input } from "gpui-base";
import { run, theme, shared, setShared, props, closeOverlay } from "herdr";

const CONTEXTS = ["work", "personal"];
const LABEL = { all: "All", work: "Work", personal: "Personal" };
const active = () => shared("space.context.active") ?? "all";
const todos = () => shared("todos") ?? [];
const save = (list) => setShared("todos", list);
const visible = (d) => active() === "all" || !d.ctx || d.ctx === active();

export function add(text) {
  text = text.trim();
  if (!text) return;
  const ctx = active() === "all" ? null : active();
  save([{ id: `${Date.now().toString(36)}${Math.random().toString(36).slice(2, 6)}`, text, ctx, done: false }, ...todos()]);
}

const update = (id, change) => save(todos().map((d) => (d.id === id ? { ...d, ...change } : d)));

export default class Todos extends View {
  init(_props, cx) {
    this.dialog = Boolean(props()?.add);
    this.input = InputState.new({ placeholder: this.dialog ? "What needs doing?" : "Add a todo…" });
    this.input.on("submit", (_e, cx) => {
      add(this.input.value());
      this.input.set_value("");
      if (this.dialog) closeOverlay(props().overlay);
      cx.notify();
    });
    this.inputFocused = false;
    this.input.on("focus", (_e, cx) => { this.inputFocused = true; cx.notify(); });
    this.input.on("blur", (_e, cx) => { this.inputFocused = false; cx.notify(); });
    this.handle = cx.focus_handle();
    if (this.dialog) {
      this.input.focus();
      cx.timer.after(300, () => this.input.focus());
    }
    this.showDone = false;
    this.editing = null; // { id, input } while a todo's text is being edited
    this.pressed = null;
    this.over = null;
    this.hovered = null;
  }

  // Dropping `from` onto `to`'s place; the hidden ones (another context) keep theirs.
  move(from, to) {
    const list = [...todos()];
    const i = list.findIndex((d) => d.id === from), j = list.findIndex((d) => d.id === to);
    if (i === -1 || j === -1 || i === j) return;
    list.splice(j, 0, list.splice(i, 1)[0]);
    save(list);
  }

  // Double-click: the text becomes an input. Enter or leaving it saves (empty
  // keeps the old text), Esc cancels.
  edit(d, cx) {
    const input = InputState.new({ value: d.text });
    input.set_selected_range({ start: 0, end: d.text.length });
    const finish = (keep, cx) => {
      if (this.editing?.input !== input) return;
      const text = input.value().trim();
      if (keep && text && text !== d.text) update(d.id, { text });
      this.editing = null;
      cx.notify();
    };
    input.on("submit", (_e, cx) => finish(true, cx));
    input.on("blur", (_e, cx) => finish(true, cx));
    this.editing = { id: d.id, input, cancel: (cx) => finish(false, cx) };
    input.focus();
    cx.notify();
  }

  send(d) {
    const name = d.text.length > 24 ? `${d.text.slice(0, 23)}…` : d.text;
    run("tab.new", { name, argv: ["claude"], task: d.text });
    update(d.id, { sent: true });
  }

  inputBox(t) {
    return Input.new(this.input).h(32).px(10).rounded(8).border_1()
      .border_color(this.inputFocused ? t.accent : t.input).bg(t.background).text_size(12.5).text_color(t.foreground);
  }

  icon(id, glyph, tip, t, action) {
    return div().id(id).flex_none().size(20).rounded(5).flex().items_center().justify_center()
      .text_size(12).text_color(t.dim).cursor_pointer()
      .hover((s) => s.bg(t.hover).text_color(t.foreground))
      .tooltip(tip)
      .on_mouse_down("left", (_e, cx) => cx.stop_propagation())
      .on_click((_e, cx) => { cx.stop_propagation(); action(); cx.notify(); })
      .child(glyph);
  }

  row(d, t, order) {
    const hovered = this.hovered === d.id;
    const from = order.indexOf(this.pressed), at = order.indexOf(d.id);
    const ctxColor = d.ctx === "work" ? t.ansi4 : d.ctx === "personal" ? t.ansi2 : t.dim;
    return h_flex().relative().id(`todo-${d.id}`).min_h(30).px(8).py(4).gap(8).items_center().rounded(7)
      .hover((s) => s.bg(t.hover))
      .when(this.pressed === d.id && this.over !== d.id, (el) => el.opacity(0.5))
      .when(!d.done && this.pressed !== null && this.over === d.id && this.pressed !== d.id, (el) => el.child(
        div().absolute().left(0).right(0).h(2).bg(t.accent)
          .when(from < at, (line) => line.bottom(0))
          .when(from > at, (line) => line.top(0))))
      .on_hover((on, cx) => {
        if (on) this.hovered = d.id; else if (this.hovered === d.id) this.hovered = null;
        cx.notify();
      })
      .when(!d.done, (el) => el
        .on_mouse_down("left", () => { this.pressed = d.id; this.over = d.id; })
        .on_mouse_move((_e, cx) => {
          if (this.pressed !== null && this.over !== d.id) { this.over = d.id; cx.notify(); }
        })
        .on_mouse_up("left", (_e, cx) => {
          if (this.pressed && this.pressed !== d.id) this.move(this.pressed, d.id);
          this.pressed = null; this.over = null;
          cx.notify();
        }))
      .child(div().id(`todo-box-${d.id}`).flex_none().size(14).rounded(4).border_1()
        .border_color(d.done ? t.dim : t.input).when(d.done, (el) => el.bg(t.dim))
        .flex().items_center().justify_center().text_size(10).text_color(t.background)
        .cursor_pointer().hover((s) => s.border_color(t.accent))
        .on_mouse_down("left", (_e, cx) => cx.stop_propagation())
        .on_click((_e, cx) => { cx.stop_propagation(); update(d.id, { done: !d.done }); cx.notify(); })
        .child(d.done ? "✓" : ""))
      .child(this.editing?.id === d.id
        ? div().flex_1().min_w(0)
          .on_key_down((e, cx) => { if (e.key === "escape") { cx.stop_propagation(); this.editing.cancel(cx); } })
          .on_mouse_down("left", (_e, cx) => cx.stop_propagation())
          .child(Input.new(this.editing.input).h(24).px(6).rounded(5).border_1().border_color(t.accent)
            .bg(t.background).text_size(12.5).text_color(t.foreground))
        : div().id(`todo-text-${d.id}`).flex_1().min_w(0).text_size(12.5)
          .text_color(d.done ? t.dim : t.foreground).when(d.done, (el) => el.line_through())
          .on_mouse_down("left", (e, cx) => { if (e.click_count === 2) { cx.stop_propagation(); this.pressed = null; this.edit(d, cx); } })
          .child(d.text))
      .when(Boolean(d.sent) && !hovered, (el) => el.child(div().flex_none().text_size(11).text_color(t.dim).tooltip("Sent to an agent").child("↗")))
      .when(hovered, (el) => el
        .when(!d.done, (el) => el.child(this.icon(`todo-send-${d.id}`, "↗", "Start Claude on this in a new tab", t, () => this.send(d))))
        .child(this.icon(`todo-del-${d.id}`, "×", "Delete", t, () => save(todos().filter((x) => x.id !== d.id)))))
      .child(div().id(`todo-ctx-${d.id}`).flex_none().w(16).h(16).rounded(4).flex().items_center().justify_center()
        .text_size(10).font_bold().text_color(ctxColor).when(!d.ctx, (el) => el.opacity(0.35))
        .cursor_pointer().hover((s) => s.bg(t.raised).opacity(1))
        .tooltip(d.ctx ? `${LABEL[d.ctx]} · click to change` : "No context (shows everywhere) · click to tag")
        .on_mouse_down("left", (_e, cx) => cx.stop_propagation())
        .on_click((_e, cx) => {
          cx.stop_propagation();
          update(d.id, { ctx: [null, ...CONTEXTS][([null, ...CONTEXTS].indexOf(d.ctx ?? null) + 1) % 3] });
          cx.notify();
        })
        .child(d.ctx ? d.ctx[0].toUpperCase() : "·"));
  }

  render() {
    const t = theme();
    if (this.dialog) {
      return v_flex().size_full().p(18).gap(12).bg(t.popover).text_color(t.foreground)
        .child(h_flex().items_center()
          .child(div().flex_1().text_size(15).font_semibold().child("New todo"))
          .child(div().text_size(11).text_color(t.dim).child(active() === "all" ? "Esc" : `${LABEL[active()]} · Esc`)))
        .child(this.inputBox(t));
    }
    const list = todos().filter(visible);
    const open = list.filter((d) => !d.done), done = list.filter((d) => d.done);
    const order = open.map((d) => d.id);
    return v_flex().size_full().min_h(0).bg(t.chrome).text_color(t.foreground).text_size(13)
      .on_mouse_up("left", (_e, cx) => { this.pressed = null; this.over = null; cx.notify(); })
      .child(h_flex().h(36).px(14).flex_none().items_center().gap(6).text_size(11.5).text_color(t.dim)
        .child(div().font_medium().child("Todos"))
        .when(open.length > 0, (el) => el.child(div().child(String(open.length))))
        .child(div().flex_1())
        .child(div().child(LABEL[active()])))
      .child(div().px(10).pb(8).flex_none().child(this.inputBox(t)))
      .child(v_flex().id("todo-list").flex_1().min_h(0).px(6).pb(10).overflow_y_scrollbar()
        .when(list.length === 0, (el) => el.child(div().px(8).pt(6).text_size(12).text_color(t.dim)
          .child("Nothing yet. Type above and press Enter.")))
        .children(open.map((d) => this.row(d, t, order)))
        .when(done.length > 0, (el) => el
          .child(h_flex().id("todo-done").mt(8).px(8).h(26).gap(6).items_center().text_size(11).text_color(t.dim)
            .cursor_pointer().hover((s) => s.text_color(t.foreground))
            .on_click((_e, cx) => { this.showDone = !this.showDone; cx.notify(); })
            .child(svg(`mods/workspace-chrome/chevron-${this.showDone ? "down" : "right"}.svg`).size(11))
            .child(`Done ${done.length}`)
            .child(div().flex_1())
            .when(this.showDone, (el) => el.child(div().id("todo-clear").px(4).rounded(4).hover((s) => s.bg(t.hover))
              .on_click((_e, cx) => {
                cx.stop_propagation();
                const gone = new Set(done.map((d) => d.id));
                save(todos().filter((d) => !gone.has(d.id)));
                cx.notify();
              })
              .child("Clear"))))
          .when(this.showDone, (el) => el.children(done.map((d) => this.row(d, t, order))))));
  }
}
