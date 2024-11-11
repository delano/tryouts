{
  "targets": [
    {
      "target_name": "tree_sitter_ruby_tryouts",
      "type": "shared_library",
      "sources": [
        "src/parser.c",
        "src/scanner.c"
      ],
      "include_dirs": [
        "src"
      ],
      "cflags": [
        "-std=c99",
        "-fPIC"
      ],
      "conditions": [
        ["OS=='mac'", {
          "xcode_settings": {
            "GCC_ENABLE_CPP_EXCEPTIONS": "YES",
            "MACOSX_DEPLOYMENT_TARGET": "10.9"
          }
        }]
      ]
    }
  ]
}
