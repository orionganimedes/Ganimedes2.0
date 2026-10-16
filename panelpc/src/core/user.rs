//! Usuarios del sistema y credenciales de prueba.
//!
//! Mientras `infra/backend.rs` no esté conectado, la autenticación se resuelve
//! contra el catálogo de demostración de este módulo. Cuando se conecte
//! PocketBase, [`Usuario::autenticar`] pasa a delegar en
//! `BackendClient::auth_with_password` y este catálogo desaparece.
//!
//! El catálogo refleja los campos de `UserRecord` del backend (`role`, `chair`,
//! `shift`, `branch_code`), así que la sustitución será directa.

/// Rol del usuario, con los permisos que implica en el punto de venta.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Rol {
    /// Acceso total: catálogo, caja y cierre de sesión.
    Admin,
    /// Cobra y gestiona el carrito.
    Cajero,
    /// Atiende servicios; el catálogo de productos es de sólo lectura.
    Barbero,
}

impl Rol {
    pub const TODOS: [Rol; 3] = [Rol::Admin, Rol::Cajero, Rol::Barbero];

    /// Etiqueta para mostrar en la interfaz.
    pub fn etiqueta(&self) -> &'static str {
        match self {
            Rol::Admin => "Administrador",
            Rol::Cajero => "Cajero",
            Rol::Barbero => "Barbero",
        }
    }

    /// Identificador corto, al estilo de la colección `admins` del backend.
    pub fn clave(&self) -> &'static str {
        match self {
            Rol::Admin => "admin",
            Rol::Cajero => "cashier",
            Rol::Barbero => "barber",
        }
    }

    /// `true` si el rol puede modificar el catálogo de productos.
    pub fn puede_editar_catalogo(&self) -> bool {
        matches!(self, Rol::Admin)
    }
}

/// Usuario autenticable.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Usuario {
    pub id: &'static str,
    /// Nombre visible en la interfaz.
    pub nombre: &'static str,
    pub email: &'static str,
    pub usuario: &'static str,
    pub password: &'static str,
    pub rol: Rol,
    /// Silla asignada, si el rol atiende servicios.
    pub silla: Option<&'static str>,
    pub turno: Option<&'static str>,
    pub sucursal: &'static str,
    pub activo: bool,
}

impl Usuario {
    /// Comprueba si el identificador y la contraseña corresponden a este usuario.
    ///
    /// Se admite indistintamente el nombre de usuario o el correo, sin
    /// distinguir mayúsculas ni espacios sobrantes: el formulario muestra
    /// `ej. admin@ganimedes.pos`, así que ambos deben funcionar.
    pub fn coincide(&self, identificador: &str, password: &str) -> bool {
        let id = identificador.trim().to_ascii_lowercase();
        let usuario_ok = id == self.usuario.to_ascii_lowercase();
        let email_ok = id == self.email.to_ascii_lowercase();

        (usuario_ok || email_ok) && password == self.password
    }
}

/// Usuarios de prueba para verificar la interfaz.
///
/// Son credenciales de desarrollo: **deben eliminarse antes de desplegar**. La
/// pantalla de acceso las muestra en pantalla a propósito, para poder probar sin
/// consultar el código.
pub const USUARIOS_DEMO: &[Usuario] = &[
    Usuario {
        id: "usr_admin",
        nombre: "Ana Ruiz",
        email: "admin@ganimedes.pos",
        usuario: "admin",
        password: "admin",
        rol: Rol::Admin,
        silla: None,
        turno: Some("mañana"),
        sucursal: "MAIN01",
        activo: true,
    },
    Usuario {
        id: "usr_cajero",
        nombre: "Luis Prado",
        email: "cajero@ganimedes.pos",
        usuario: "cajero",
        password: "cajero",
        rol: Rol::Cajero,
        silla: None,
        turno: Some("tarde"),
        sucursal: "MAIN01",
        activo: true,
    },
    Usuario {
        id: "usr_barbero",
        nombre: "Marco Díaz",
        email: "barbero@ganimedes.pos",
        usuario: "barbero",
        password: "barbero",
        rol: Rol::Barbero,
        silla: Some("S-03"),
        turno: Some("mañana"),
        sucursal: "MAIN01",
        activo: true,
    },
];

/// Busca y valida unas credenciales en el catálogo de demostración.
///
/// Devuelve el usuario si existe, está activo y la contraseña es correcta.
pub fn autenticar(identificador: &str, password: &str) -> Option<&'static Usuario> {
    USUARIOS_DEMO
        .iter()
        .find(|u| u.activo && u.coincide(identificador, password))
}

/// Credenciales que se muestran como ayuda en la pantalla de acceso.
pub fn credenciales_visibles() -> Vec<(&'static str, &'static str, &'static str)> {
    USUARIOS_DEMO
        .iter()
        .filter(|u| u.activo)
        .map(|u| (u.usuario, u.password, u.rol.etiqueta()))
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn el_admin_de_demostracion_entra() {
        let u = autenticar("admin", "admin").expect("admin/admin debe valer");
        assert_eq!(u.rol, Rol::Admin);
    }

    #[test]
    fn cada_usuario_de_prueba_puede_entrar() {
        for u in USUARIOS_DEMO {
            let encontrado = autenticar(u.usuario, u.password);
            assert_eq!(
                encontrado.map(|x| x.id),
                Some(u.id),
                "el usuario {} no pudo entrar",
                u.usuario
            );
        }
    }

    #[test]
    fn el_correo_sirve_como_identificador() {
        let u = autenticar("admin@ganimedes.pos", "admin").expect("el correo debe valer");
        assert_eq!(u.usuario, "admin");
    }

    #[test]
    fn el_identificador_no_distingue_mayusculas_ni_espacios() {
        assert!(autenticar("  ADMIN  ", "admin").is_some());
        assert!(autenticar("Admin@Ganimedes.POS", "admin").is_some());
    }

    #[test]
    fn una_contrasena_incorrecta_no_entra() {
        assert!(autenticar("admin", "otra").is_none());
        assert!(autenticar("admin", "").is_none());
    }

    #[test]
    fn un_usuario_inexistente_no_entra() {
        assert!(autenticar("nadie", "nada").is_none());
        assert!(autenticar("", "").is_none());
    }

    #[test]
    fn la_contrasena_distingue_mayusculas() {
        assert!(autenticar("admin", "ADMIN").is_none());
    }

    #[test]
    fn los_usuarios_de_prueba_tienen_datos_completos() {
        for u in USUARIOS_DEMO {
            assert!(!u.id.is_empty(), "id vacío en {}", u.usuario);
            assert!(!u.nombre.is_empty(), "nombre vacío en {}", u.usuario);
            assert!(!u.usuario.is_empty(), "usuario vacío en {}", u.id);
            assert!(!u.password.is_empty(), "password vacía en {}", u.usuario);
            assert!(!u.email.is_empty(), "email vacío en {}", u.usuario);
            assert!(u.activo, "{} debería estar activo", u.usuario);
        }
    }

    #[test]
    fn solo_el_admin_edita_el_catalogo() {
        assert!(Rol::Admin.puede_editar_catalogo());
        assert!(!Rol::Cajero.puede_editar_catalogo());
        assert!(!Rol::Barbero.puede_editar_catalogo());
    }

    #[test]
    fn el_catalogo_de_prueba_cubre_los_tres_roles() {
        for rol in Rol::TODOS {
            assert!(
                USUARIOS_DEMO.iter().any(|u| u.rol == rol),
                "falta un usuario de prueba con rol {:?}",
                rol
            );
        }
    }

    #[test]
    fn las_credenciales_visibles_no_exponen_usuarios_inactivos() {
        let visibles = credenciales_visibles();
        assert_eq!(visibles.len(), USUARIOS_DEMO.len());
    }
}
