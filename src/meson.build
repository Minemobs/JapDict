japdict_sources = [
  'main.vala',
  'application.vala',
  'window.vala',
  'word.vala',
]

blueprints = custom_target('blueprints',
  input: files(
    'gtk/help-overlay.blp',
    'window.blp',
  ),
  output: '.',
  command: [find_program('blueprint-compiler'), 'batch-compile', '@OUTPUT@', '@CURRENT_SOURCE_DIR@', '@INPUT@'],
)

japdict_deps = [
  dependency('gtk4'),
  dependency('libsoup-3.0'),
  dependency('json-glib-1.0'),
  dependency('libadwaita-1', version: '>= 1.2'),
]

japdict_sources += gnome.compile_resources('japdict-resources',
  'japdict.gresource.xml',
  dependencies: blueprints,
  c_name: 'japdict'
)

executable('japdict', japdict_sources,
  dependencies: japdict_deps,
       install: true,
)