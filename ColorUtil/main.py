import gi
import json

gi.require_version("Gtk", "4.0")

from gi.repository import Gtk, Gdk

with open("/home/patoll/git/Hyprland/ColorUtil/colors.json") as f:
    colors = json.load(f)


class ColorRow(Gtk.Box):
    def __init__(self, name, hexcode):
        super().__init__(orientation=Gtk.Orientation.HORIZONTAL, spacing=12)

        rgb = self.hex_to_rgb(hexcode)

        square = Gtk.Button()
        square.set_size_request(100, 48)

        css = Gtk.CssProvider()
        css.load_from_data(f"""
        button {{
            background: {hexcode};
            border-radius: 12px;
        }}
        """.encode())

        square.get_style_context().add_provider(
            css,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        )

        square.connect("clicked", lambda *_: self.copy(hexcode))

        labels = Gtk.Box(
            orientation=Gtk.Orientation.VERTICAL,
            spacing=2
        )

        name_label = Gtk.Label(
            label=name,
            xalign=0
        )

        hex_button = Gtk.Button(label=hexcode)
        hex_button.connect(
            "clicked",
            lambda *_: self.copy(hexcode)
        )

        rgb_text = f"rgb{rgb}"

        rgb_button = Gtk.Button(label=rgb_text)
        rgb_button.connect(
            "clicked",
            lambda *_: self.copy(rgb_text)
        )

        labels.append(name_label)
        labels.append(hex_button)
        labels.append(rgb_button)

        self.append(square)
        self.append(labels)

    def hex_to_rgb(self, h):
        h = h.lstrip("#")
        return tuple(int(h[i:i+2], 16) for i in (0, 2, 4))

    def copy(self, text):
        clipboard = Gdk.Display.get_default().get_clipboard()
        clipboard.set(text)


class App(Gtk.Application):
    def __init__(self):
        super().__init__()

    def do_activate(self):
        win = Gtk.ApplicationWindow(application=self)

        win.set_title("Color Palette")
        win.set_default_size(350, 500)

        scroll = Gtk.ScrolledWindow()

        box = Gtk.Box(
            orientation=Gtk.Orientation.VERTICAL,
            spacing=8,
            margin_top=12,
            margin_bottom=12,
            margin_start=12,
            margin_end=12
        )

        for name, hexcode in colors.items():
            box.append(ColorRow(name, hexcode))

        scroll.set_child(box)

        win.set_child(scroll)
        win.present()


app = App()
app.run()