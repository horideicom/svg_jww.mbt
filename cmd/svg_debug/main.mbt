///|
using @arg {type Spec, parse}

///|
fn log_line(msg : String) -> Unit {
  @fs.write_string_to_file("/dev/stderr", msg + "\n") catch {
    _ => println(msg)
  }
}

///|
fn exit_with_error(msg : String) -> Unit {
  log_line(msg)
  @sys.exit(1)
}

///|
fn slice_to_string(s : String, start : Int, end : Int) -> String {
  try s[start:end] catch {
    _ => s
  } noraise {
    view => view.to_string()
  }
}

///|
fn default_output_path(input : String) -> String {
  match input.rev_find(".") {
    Some(idx) => {
      let suffix = slice_to_string(input, idx, input.length()).to_lower()
      if suffix == ".jww" {
        let prefix = slice_to_string(input, 0, idx)
        prefix + ".svg"
      } else {
        input + ".svg"
      }
    }
    None => input + ".svg"
  }
}

///|
fn has_suffix(value : String, suffix : String) -> Bool {
  if value.length() < suffix.length() {
    false
  } else {
    let start = value.length() - suffix.length()
    slice_to_string(value, start, value.length()).to_lower() == suffix
  }
}

///|
fn is_js_entry_path(value : String) -> Bool {
  has_suffix(value, ".js") ||
  has_suffix(value, ".mjs") ||
  has_suffix(value, ".cjs")
}

///|
fn append_indent(sb : StringBuilder, level : Int, pretty : Bool) -> Unit {
  if pretty {
    for _ in 0..<level {
      sb.write_string("  ")
    }
  }
}

///|
fn append_newline(sb : StringBuilder, pretty : Bool) -> Unit {
  if pretty {
    sb.write_char('\n')
  }
}

///|
fn append_json_string(sb : StringBuilder, value : String) -> Unit {
  sb.write_char('"')
  for ch in value {
    match ch {
      '\\' => sb.write_string("\\\\")
      '"' => sb.write_string("\\\"")
      '\n' => sb.write_string("\\n")
      '\r' => sb.write_string("\\r")
      '\t' => sb.write_string("\\t")
      _ => sb.write_char(ch)
    }
  }
  sb.write_char('"')
}

///|
fn append_key(
  sb : StringBuilder,
  key : String,
  level : Int,
  pretty : Bool,
) -> Unit {
  append_indent(sb, level, pretty)
  append_json_string(sb, key)
  sb.write_char(':')
  if pretty {
    sb.write_char(' ')
  }
}

///|
fn append_bool(sb : StringBuilder, value : Bool) -> Unit {
  if value {
    sb.write_string("true")
  } else {
    sb.write_string("false")
  }
}

///|
fn build_metadata_json(
  parsed : @lib.ParsedDocument,
  debug : @lib.DebugOptions,
  pretty : Bool,
) -> String {
  let sb = StringBuilder::new()
  let bounds = parsed.bounds
  let counts = parsed.entity_counts
  let ps = parsed.print_settings
  sb.write_char('{')
  append_newline(sb, pretty)
  append_key(sb, "version", 1, pretty)
  append_json_string(sb, parsed.version)
  sb.write_char(',')
  append_newline(sb, pretty)
  append_key(sb, "paper_size", 1, pretty)
  sb.write_string(parsed.paper_size.to_string())
  sb.write_char(',')
  append_newline(sb, pretty)
  append_key(sb, "memo", 1, pretty)
  append_json_string(sb, parsed.memo)
  sb.write_char(',')
  append_newline(sb, pretty)
  append_key(sb, "bounds", 1, pretty)
  sb.write_char('{')
  append_newline(sb, pretty)
  append_key(sb, "min_x", 2, pretty)
  sb.write_string(bounds.min_x.to_string())
  sb.write_char(',')
  append_newline(sb, pretty)
  append_key(sb, "min_y", 2, pretty)
  sb.write_string(bounds.min_y.to_string())
  sb.write_char(',')
  append_newline(sb, pretty)
  append_key(sb, "max_x", 2, pretty)
  sb.write_string(bounds.max_x.to_string())
  sb.write_char(',')
  append_newline(sb, pretty)
  append_key(sb, "max_y", 2, pretty)
  sb.write_string(bounds.max_y.to_string())
  sb.write_char(',')
  append_newline(sb, pretty)
  append_key(sb, "width", 2, pretty)
  sb.write_string((bounds.max_x - bounds.min_x).to_string())
  sb.write_char(',')
  append_newline(sb, pretty)
  append_key(sb, "height", 2, pretty)
  sb.write_string((bounds.max_y - bounds.min_y).to_string())
  append_newline(sb, pretty)
  append_indent(sb, 1, pretty)
  sb.write_char('}')
  sb.write_char(',')
  append_newline(sb, pretty)
  append_key(sb, "entity_counts", 1, pretty)
  sb.write_char('{')
  append_newline(sb, pretty)
  append_key(sb, "lines", 2, pretty)
  sb.write_string(counts.lines.to_string())
  sb.write_char(',')
  append_newline(sb, pretty)
  append_key(sb, "arcs", 2, pretty)
  sb.write_string(counts.arcs.to_string())
  sb.write_char(',')
  append_newline(sb, pretty)
  append_key(sb, "texts", 2, pretty)
  sb.write_string(counts.texts.to_string())
  sb.write_char(',')
  append_newline(sb, pretty)
  append_key(sb, "points", 2, pretty)
  sb.write_string(counts.points.to_string())
  sb.write_char(',')
  append_newline(sb, pretty)
  append_key(sb, "solids", 2, pretty)
  sb.write_string(counts.solids.to_string())
  sb.write_char(',')
  append_newline(sb, pretty)
  append_key(sb, "blocks", 2, pretty)
  sb.write_string(counts.blocks.to_string())
  sb.write_char(',')
  append_newline(sb, pretty)
  append_key(sb, "images", 2, pretty)
  sb.write_string(counts.images.to_string())
  append_newline(sb, pretty)
  append_indent(sb, 1, pretty)
  sb.write_char('}')
  sb.write_char(',')
  append_newline(sb, pretty)
  append_key(sb, "layers", 1, pretty)
  sb.write_char('[')
  append_newline(sb, pretty)
  for i in 0..<parsed.layers.length() {
    let layer = parsed.layers[i]
    append_indent(sb, 2, pretty)
    sb.write_char('{')
    append_newline(sb, pretty)
    append_key(sb, "id", 3, pretty)
    sb.write_string(layer.id.to_string())
    sb.write_char(',')
    append_newline(sb, pretty)
    append_key(sb, "name", 3, pretty)
    append_json_string(sb, layer.name)
    sb.write_char(',')
    append_newline(sb, pretty)
    append_key(sb, "entity_count", 3, pretty)
    sb.write_string(layer.entity_count.to_string())
    sb.write_char(',')
    append_newline(sb, pretty)
    append_key(sb, "visible", 3, pretty)
    append_bool(sb, layer.visible)
    append_newline(sb, pretty)
    append_indent(sb, 2, pretty)
    sb.write_char('}')
    if i + 1 < parsed.layers.length() {
      sb.write_char(',')
    }
    append_newline(sb, pretty)
  }
  append_indent(sb, 1, pretty)
  sb.write_char(']')
  sb.write_char(',')
  append_newline(sb, pretty)
  append_key(sb, "print_settings", 1, pretty)
  sb.write_char('{')
  append_newline(sb, pretty)
  append_key(sb, "origin_x", 2, pretty)
  sb.write_string(ps.origin_x.to_string())
  sb.write_char(',')
  append_newline(sb, pretty)
  append_key(sb, "origin_y", 2, pretty)
  sb.write_string(ps.origin_y.to_string())
  sb.write_char(',')
  append_newline(sb, pretty)
  append_key(sb, "scale", 2, pretty)
  sb.write_string(ps.scale.to_string())
  sb.write_char(',')
  append_newline(sb, pretty)
  append_key(sb, "rotation_setting", 2, pretty)
  sb.write_string(ps.rotation_setting.to_string())
  append_newline(sb, pretty)
  append_indent(sb, 1, pretty)
  sb.write_char('}')
  sb.write_char(',')
  append_newline(sb, pretty)
  append_key(sb, "debug", 1, pretty)
  sb.write_char('{')
  append_newline(sb, pretty)
  append_key(sb, "show_bounds", 2, pretty)
  append_bool(sb, debug.show_bounds)
  sb.write_char(',')
  append_newline(sb, pretty)
  append_key(sb, "show_axes", 2, pretty)
  append_bool(sb, debug.show_axes)
  sb.write_char(',')
  append_newline(sb, pretty)
  append_key(sb, "show_print_area", 2, pretty)
  append_bool(sb, debug.show_print_area)
  append_newline(sb, pretty)
  append_indent(sb, 1, pretty)
  sb.write_char('}')
  append_newline(sb, pretty)
  sb.write_char('}')
  sb.to_string()
}

///|
fn write_file_or_exit(path : String, content : String) -> Unit {
  @fs.write_string_to_file(path, content) catch {
    err => exit_with_error("Failed to write " + path + ": " + err.to_string())
  }
}

///|
fn main {
  let argv = @sys.get_cli_args()
  let args = []
  let start = if argv.length() > 0 && is_js_entry_path(argv[0]) { 1 } else { 0 }
  for i in start..<argv.length() {
    let arg = argv[i]
    if arg != "--" {
      args.push(arg)
    }
  }
  let output = @ref.new("")
  let json_out = @ref.new("")
  let want_json = @ref.new(false)
  let pretty = @ref.new(false)
  let debug = @ref.new(false)
  let show_bounds = @ref.new(false)
  let show_axes = @ref.new(false)
  let show_print = @ref.new(false)
  let verbose = @ref.new(false)
  let inputs : Array[String] = []
  let spec : Array[(String, String, Spec, String)] = [
    ("--output", "-o", Spec::Set_string(output), "write SVG to file"),
    ("--json", "-j", Spec::Set(want_json), "emit metadata JSON to stdout"),
    (
      "--json-out",
      "-J",
      Spec::Set_string(json_out),
      "write metadata JSON to file",
    ),
    ("--pretty", "-P", Spec::Set(pretty), "pretty-print JSON"),
    (
      "--debug",
      "-d",
      Spec::Set(debug),
      "enable debug overlays + metadata + logs",
    ),
    (
      "--overlay-bounds",
      "-b",
      Spec::Set(show_bounds),
      "overlay document bounds",
    ),
    ("--overlay-axes", "-a", Spec::Set(show_axes), "overlay X/Y axes"),
    ("--overlay-print", "-p", Spec::Set(show_print), "overlay print area"),
    ("--verbose", "-v", Spec::Set(verbose), "verbose logging"),
  ]
  let usage =
    #| svg-jww-debug
    #| usage:
    #|   svg-jww-debug [options] <input.jww>
    #|
    #| Outputs SVG to a file and optional debug metadata as JSON.
    #|
  parse(spec, arg => inputs.push(arg), usage, args) catch {
    @arg.ErrorMsg(msg) => exit_with_error(msg.trim_end().to_string())
    err => exit_with_error(err.to_string())
  }
  if inputs.length() == 0 {
    exit_with_error(usage.trim_end().to_string())
  }
  if inputs.length() > 1 {
    exit_with_error("Only one input file is supported")
  }
  let input = inputs[0]
  let debug_enabled = debug.val
  let debug_opts = @lib.DebugOptions::new(
    show_bounds.val || debug_enabled,
    show_axes.val || debug_enabled,
    show_print.val || debug_enabled,
  )
  let use_debug_svg = debug_opts.show_bounds ||
    debug_opts.show_axes ||
    debug_opts.show_print_area
  let emit_json = want_json.val || debug_enabled || json_out.val != ""
  let emit_logs = verbose.val || debug_enabled
  let output_path = if output.val == "" {
    default_output_path(input)
  } else {
    output.val
  }
  if output_path == "-" && emit_json && json_out.val == "" {
    exit_with_error("Use --json-out when writing SVG to stdout")
  }
  if emit_logs {
    log_line("Reading " + input)
  }
  let data = @fs.read_file_to_bytes(input) catch {
    err => {
      exit_with_error("Failed to read " + input + ": " + err.to_string())
      b""
    }
  }
  let parsed = if use_debug_svg {
    @lib.jww_parse_debug(data, debug_opts)
  } else {
    @lib.jww_parse(data)
  }
  if emit_logs {
    log_line("SVG size: " + parsed.svg.length().to_string() + " bytes")
  }
  if output_path == "-" {
    println(parsed.svg)
  } else {
    if emit_logs {
      log_line("Writing SVG to " + output_path)
    }
    write_file_or_exit(output_path, parsed.svg)
  }
  if emit_json {
    let json_str = build_metadata_json(parsed, debug_opts, pretty.val)
    if json_out.val != "" {
      if emit_logs {
        log_line("Writing metadata JSON to " + json_out.val)
      }
      write_file_or_exit(json_out.val, json_str + "\n")
    } else {
      println(json_str)
    }
  }
}
