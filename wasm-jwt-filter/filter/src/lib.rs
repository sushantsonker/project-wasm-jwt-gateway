use proxy_wasm::traits::*;
use proxy_wasm::types::*;

struct JwtFilter;

impl Context for JwtFilter {}
impl HttpContext for JwtFilter {
    fn on_http_request_headers(&mut self, _: usize, _: bool) -> Action {
        // TODO: extract Authorization header, verify JWT, enforce claims
        // If invalid: return Action::Pause and send local response
        // If valid: return Action::Continue
        Action::Continue
    }
}

impl RootContext for JwtFilter {
    fn on_configure(&mut self, _size: usize) -> bool {
        // TODO: parse configuration (e.g. JWK URI, audiences, issuers)
        true
    }

    fn create_http_context(&self, _: u32) -> Option<Box<dyn HttpContext>> {
        Some(Box::new(JwtFilter))
    }

    fn get_type(&self) -> Option<ContextType> {
        Some(ContextType::HttpContext)
    }
}

proxy_wasm::main! {{
    proxy_wasm::set_root_context(|_context_id| Box::new(JwtFilter));
}}
