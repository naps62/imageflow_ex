extern crate imageflow_types;

use rustler::{Binary, Encoder, Env, Error, Term};

mod job;

mod atoms {
    rustler::rustler_atoms! {
        atom ok;
        atom error;
    }
}

use job::Job;

rustler::rustler_export_nifs! {
    "Elixir.Imageflow.NIF",
    [
        ("get_long_version_string", 0, get_long_version_string),
        ("job_create", 0, job_create),
        ("job_destroy", 1, job_destroy),
        ("job_add_input_buffer", 3, job_add_input_buffer),
        ("job_add_input_file", 3, job_add_input_file),
        ("job_add_output_buffer", 2, job_add_output_buffer),
        ("job_get_output_buffer", 2, job_get_output_buffer),
        ("job_save_output_to_file", 3, job_save_output_to_file),
        ("job_message", 3, job_message),
    ],
    None
}

macro_rules! job {
    ($id:expr) => {{
        Job::load_from_id($id.decode()?).ok().unwrap()
    }};
}

fn get_long_version_string<'a>(_env: Env<'a>, _args: &[Term<'a>]) -> String {
    imageflow_types::version::one_line_version()
}

pub fn job_create<'a>(env: Env<'a>, _args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    match Job::create() {
        Ok(id) => Ok((atoms::ok(), id).encode(env)),
        Err(_e) => Err(rustler::Error::Atom("Unable to create context")),
    }
}

pub fn job_destroy<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    Job::destroy_from_id(args[0].decode()?).ok().unwrap();

    Ok(atoms::ok().encode(env))
}

pub fn job_add_input_buffer<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let io_id: i32 = args[1].decode()?;
    let bytes: Binary = args[2].decode()?;

    match job!(args[0]).add_input_buffer(io_id, bytes.as_slice()) {
        Ok(_) => Ok(atoms::ok().encode(env)),
        Err(msg) => Ok((atoms::error(), msg).encode(env)),
    }
}

pub fn job_add_input_file<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let io_id: i32 = args[1].decode()?;
    let path: String = args[2].decode()?;

    match job!(args[0]).add_input_file(io_id, &path) {
        Ok(_) => Ok(atoms::ok().encode(env)),
        Err(msg) => Ok((atoms::error(), msg).encode(env)),
    }
}

pub fn job_add_output_buffer<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let io_id: i32 = args[1].decode()?;

    match job!(args[0]).add_output_buffer(io_id) {
        Ok(_) => Ok(atoms::ok().encode(env)),
        Err(msg) => Ok((atoms::error(), msg).encode(env)),
    }
}

pub fn job_get_output_buffer<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let io_id: i32 = args[1].decode()?;

    match job!(args[0]).get_output_buffer(io_id) {
        Ok(buffer) => Ok((atoms::ok(), buffer).encode(env)),
        Err(e) => Ok((atoms::error(), e.to_string()).encode(env)),
    }
}

pub fn job_save_output_to_file<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let io_id: i32 = args[1].decode()?;
    let path: String = args[2].decode()?;

    match job!(args[0]).save_output_to_file(io_id, &path) {
        Ok(_) => Ok(atoms::ok().encode(env)),
        Err(e) => Ok((atoms::error(), e.to_string()).encode(env)),
    }
}

pub fn job_message<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let method: String = args[1].decode()?;
    let message: String = args[2].decode()?;

    match job!(args[0]).message(&method, &message) {
        Ok(resp) => Ok((atoms::ok(), resp.response_json.encode(env)).encode(env)),
        Err(msg) => Ok((atoms::error(), msg.encode(env)).encode(env)),
    }
}
