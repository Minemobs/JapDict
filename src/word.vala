namespace Japdict {
    public class Word : Object {
        private Soup.Session session;
        private Json.Parser parser;
        private Gtk.ListBox list;
        private Gtk.SearchEntry input;
        private Gdk.Clipboard clipboard;
        private Window window;

        public Word(Gtk.ListBox _list, Gtk.SearchEntry _input, Window window) {
            list = _list;
            //list.row_activated.connect (on_row_activated);
            input = _input;
            session = new Soup.Session ();
            parser = new Json.Parser ();
            Gdk.Display display = Gdk.Display.get_default ();
            clipboard = display.get_clipboard ();
            this.window = window;
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
            var widget = list.get_first_child () as Adw.ExpanderRow;
            while(widget != null) {
                list.remove(widget);
                widget = list.get_first_child () as Adw.ExpanderRow;
            }
        }

        private void parse (string input) throws Error {
            parser.load_from_data (input, -1);
            list.get_parent ().set_visible (true);
            if(parser.get_root().get_object ().get_object_member ("meta").get_int_member ("status") != 200) {
                message ("Jisho returned non 200 ");
                return;
            }
            var data_array = parser.get_root ().get_object ().get_array_member ("data");
            uint max = uint.min(5, data_array.get_length ());
            for(uint i = 0; i < max; i++) {
                var data = data_array.get_element(i).get_object ();
                string slug = data.get_string_member ("slug").split("-")[0];

                var expander = new Adw.ExpanderRow ();
                expander.set_margin_top (10);
                expander.set_margin_bottom (10);
                expander.set_margin_start (10);
                expander.set_margin_end (10);
                expander.set_title(slug);

                parse_senses (data, expander);
                list.append(expander);
            }
        }

        private void parse_senses(Json.Object data, Adw.ExpanderRow expander_row) {
            var senses = data.get_array_member ("senses");
            for(uint i = 0; i < senses.get_length (); i++) {
                var defs = senses.get_element (i).get_object().get_array_member ("english_definitions");
                var str = new GLib.StringBuilder ();
                for(uint j = 0; j < defs.get_length (); j++) {
                    bool isLast = j == (defs.get_length () - 1);
                    var text = defs.get_element (j).get_string ();
                    if(text == null || text.length == 0) continue;
                    str.append(text + (isLast ? "" : " / "));
                }
                var row = new Adw.ActionRow ();
                row.set_title (str.str);
                row.activatable = true;
                row.activated.connect((self) => clipboard.set_text (self.get_title ()));
                expander_row.add_row (row);
            }
        }
    }
}
