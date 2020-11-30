extern crate imageflow_types;

use rustler::{Env, Term};

mod job;

mod atoms {
    rustler::rustler_atoms! {
        atom ok;
        atom error;
        //atom __true__ = "true";
        //atom __false__ = "false";
    }
}

rustler::rustler_export_nifs! {
    "Elixir.Imageflow.Native",
    [
        ("get_long_version_string", 0, get_long_version_string),
        ("job_create", 0, job::create),
        ("job_destroy", 1, job::destroy),
        ("job_add_input", 3, job::add_input),
        ("job_get_output", 1, job::get_output),
        ("job_message", 3, job::message),
    ],
    None
}

fn get_long_version_string<'a>(_env: Env<'a>, _args: &[Term<'a>]) -> String {
    imageflow_types::version::one_line_version()
}
