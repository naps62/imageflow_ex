extern crate imageflow_types;

use rustler::{Atom, Binary, Error, NifResult};

mod job;

mod atoms {
    rustler::atoms! {
        ok,
        error
    }
}

use atoms::ok;
use job::Job;

rustler::init!(
    "Elixir.Imageflow.Native",
    [
        get_long_version_string,
        job_create,
        job_destroy,
        job_add_input_buffer,
        job_add_input_file,
        job_add_output_buffer,
        job_get_output_buffer,
        job_save_output_to_file,
        job_message,
    ]
);

macro_rules! job {
    ($id:expr) => {{
        Job::load_from_id($id).ok().unwrap()
    }};
}

macro_rules! boxed_error {
    ($error:expr) => {{
        Error::Term(Box::new($error))
    }};
}

#[rustler::nif]
fn get_long_version_string() -> String {
    imageflow_types::version::one_line_version()
}

#[rustler::nif]
pub fn job_create() -> NifResult<(Atom, usize)> {
    match Job::create() {
        Ok(id) => Ok((ok(), id)),
        Err(e) => Err(boxed_error!(e.message)),
    }
}

#[rustler::nif]
pub fn job_destroy(job_id: usize) -> NifResult<Atom> {
    match Job::destroy_from_id(job_id) {
        Ok(_) => Ok(ok()),
        Err(e) => Err(boxed_error!(e)),
    }
}

#[rustler::nif]
pub fn job_add_input_buffer(job_id: usize, io_id: i32, bytes: Binary) -> NifResult<Atom> {
    job!(job_id).add_input_buffer(io_id, bytes.as_slice());

    Ok(ok())
}

#[rustler::nif]
pub fn job_add_input_file(job_id: usize, io_id: i32, path: String) -> NifResult<Atom> {
    match job!(job_id).add_input_file(io_id, &path) {
        Ok(_) => Ok(ok()),
        Err(e) => Err(boxed_error!(e.message)),
    }
}

#[rustler::nif]
pub fn job_add_output_buffer(job_id: usize, io_id: i32) -> NifResult<Atom> {
    job!(job_id).add_output_buffer(io_id);

    Ok(ok())
}

#[rustler::nif]
pub fn job_get_output_buffer(job_id: usize, io_id: i32) -> NifResult<(Atom, Vec<u8>)> {
    match job!(job_id).get_output_buffer(io_id) {
        Ok(buffer) => Ok((ok(), buffer)),
        Err(e) => Err(boxed_error!(e.to_string())),
    }
}

#[rustler::nif]
pub fn job_save_output_to_file(job_id: usize, io_id: i32, path: String) -> NifResult<Atom> {
    match job!(job_id).save_output_to_file(io_id, &path) {
        Ok(_) => Ok(ok()),
        Err(e) => Err(boxed_error!(e.to_string())),
    }
}

#[rustler::nif]
pub fn job_message(job_id: usize, method: String, message: String) -> Result<String, String> {
    job!(job_id).message(&method, &message)
}
