AT_COMPILE_TIME :: true;

#if AT_COMPILE_TIME {
  #run {
    set_build_options_dc(.{do_output = false});
    if !generate_bindings() {
      compiler_set_workspace_status(.FAILED);
    }
  };
} else {
  #import "System";

  main :: () {
    set_working_directory(path_strip_filename(get_path_of_running_executable()));
    if !generate_bindings() {
      exit(1);
    }
  }
}

generate_bindings :: () -> bool {
  result := true;

  output_filename: string;
  options: Generate_Bindings_Options;

  {
    using options;
    options = .{};

    old_working_dir := get_working_directory();
    set_working_directory("modules/WASAPI");
    defer set_working_directory(old_working_dir);

    array_add(*system_library_names, "ole32");
    output_filename  = "module_GENERATED.jai";

    array_add(
      *source_files,
      "wasapi.c",
    );

    array_add(
      *path_fragments_to_treat_as_non_system_paths,
      "Audioclient.h",
      "AudioSessionTypes.h",
      // "mediaobj.h",
      "mmdeviceapi.h",
      // "propsys.h",
      // "sapi.h",
      // "strmif.h",
    );

    array_add(
      *system_types_to_include,
      "BSTR",
      "CONDITION_OPERATION",
      "IPropertyStore",
      "IPropertyStoreVtbl",
      "IStream",
      "LPBYTE",
      "LPCGUID",
      "OLECHAR",
      "PCONTEXT",
      "PROPERTYKEY",
      "PROPVARIANT",
      "REFERENCE_TIME",
      "SHCOLSTATEF",
      "STATSTG",
      "tWAVEFORMATEX",
      "VARTYPE",
      "WAVEFORMATEX",
    );

    array_add(
      *extra_clang_arguments,
      "-DCINTERFACE"  // Make sure that we get a C-style interface instead of trying to deal with C++ classes...
    );

    add_generator_command               = false;
    alias_original_enum_names           = false;
    log_stripped_declarations           = false;
    generate_compile_time_struct_checks = false;

    print("Generating WASAPI bindings...\n");
    result = result && generate_one_binding(options, output_filename);
  }

  return result;
}

generate_one_binding :: (options: Generate_Bindings_Options, output_filename: string) -> bool {
  bindings_builder, success := generate_bindings(options, log_results = true);
  if !success return false;

  success = write_entire_file(output_filename, builder_to_string(*bindings_builder));
  if !success {
    log_error("Could not write generated output to \"%\"\n", output_filename);
    return false;
  }
  log("\nOK! generated '%'\n", output_filename);

  return true;
}

#import "Basic";
#import "Bindings_Generator";
#import "Compiler";
#import "Debug";
#import "File";
#import "String";

#if OS == .WINDOWS {
  #import "Windows";
}
else {
  #import "POSIX";
}