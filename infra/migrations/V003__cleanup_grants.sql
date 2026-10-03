-- V003: DELETE mínimo para limpieza de credenciales expiradas (T033).
-- AGENTS.md §5.2: `paseo_app` solo recibe los GRANT que necesita el caso de uso.
GRANT DELETE ON app.verification_codes TO paseo_app;
GRANT DELETE ON app.password_resets      TO paseo_app;
GRANT DELETE ON app.refresh_tokens       TO paseo_app;