namespace Japdict {
    public class Word : Object {
        private Soup.Session session;
        private Json.Parser parser;
        private Gtk.ListBox list;
        private Gtk.SearchEntry input;
        private Gdk.Clipboard clipboard;

        public Word(Gtk.ListBox _list, Gtk.SearchEntry _input) {
            list = _list;
            list.row_activated.connect (on_row_activated);
            input = _input;
            session = new Soup.Session ();
            parser = new Json.Parser ();
            Gdk.Display display = Gdk.Display.get_default ();
            clipboard = display.get_clipboard ();
        }

        public void on_input () {
            clear ();
            var text = input.get_text ();
            var msg = new Soup.Message ("GET", "https://jisho.org/api/v1/search/words?keyword=" + text);
            try {
                var bytes = session.send_and_read (msg);
                string str = (string)bytes.get_data();
                parse(str);
            } catch(Error e) {
                message ("error: %s".printf(e.message));
            }
        }

        private void clear () {
            var widget = list.get_first_child ();
            while(widget != null) {
                list.remove(widget);
                widget = list.get_first_child ();
            }
        }

        private void parse (string input) throws Error {
            parser.load_from_data (input, -1);
            list.get_parent ().set_visible (true);
            var data_array = parser.get_root ().get_object ().get_array_member ("data");
            uint max = uint.min(5, data_array.get_length ());
            for(uint i = 0; i < max; i++) {
                var data = data_array.get_element(i).get_object ();
                string slug = data.get_string_member ("slug").split("-")[0];
                var senses = parse_senses (data);
                var list_row = new Gtk.ListBoxRow ();
                var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 10);
                box.set_homogeneous (false);
                var slug_label = new Gtk.Label (slug);
                box.append (slug_label);
                var senses_label = new Gtk.Label (senses);
                box.append (senses_label);
                senses_label.wrap_mode = Pango.WrapMode.WORD;
                senses_label.wrap = true;
                list_row.set_child (box);
                box.set_margin_bottom(10);
                box.set_margin_start(10);
                box.set_margin_end(10);
                senses_label.set_halign (Gtk.Align.BASELINE);
                list.append(list_row);
            }
        }

        private string parse_senses(Json.Object data) {
            var senses = data.get_array_member ("senses");
            var buffer = new StringBuilder ();
            for(uint i = 0; i < senses.get_length (); i++) {
                buffer.append("%s %u) ".printf(i == 0 ? "" : " |", i));
                var defs = senses.get_element (i).get_object().get_array_member ("english_definitions");
                defs.foreach_element ((_, i, def) => buffer.append(def.get_string () + (i == (defs.get_length () - 1) ? "" : " / ")));
                if(senses.get_length() == i) buffer.append(" ;");
            }
            return buffer.str;
        }

        private void on_row_activated(Gtk.ListBoxRow row) {
            Gtk.Box box = row.get_child () as Gtk.Box;
            if(box == null) return;
            Gtk.Label label = box.get_first_child () as Gtk.Label;
            if(label == null) return;
            clipboard.set_text (label.get_text());
        }
    }
}
