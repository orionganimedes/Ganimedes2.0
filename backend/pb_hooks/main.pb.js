/// <reference path="../pb_data/types.d.ts" />

// Hooks de negocio (modo pruebas, mínimo):
// - Auto-generación de folio de venta si no se proporciona.
// (Se quitaron el hash de PIN y el forzado de rol porque rompían el login
//  por PIN y el registro de administradores desde la app Flutter.)

onRecordCreateRequest((e) => {
    if (!e.record.get("folio")) {
        const d = new Date().toISOString().slice(0, 10).replace(/-/g, "");
        const suffix = $security.randomStringWithAlphabet(5, "0123456789");
        e.record.set("folio", "#TK-" + d + "-" + suffix);
    }
    e.next();
}, "sales");
