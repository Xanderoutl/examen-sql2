USE inmobiliaria_db;

DELIMITER //

DROP TRIGGER IF EXISTS trg_auditoria_estado_propiedad //
CREATE TRIGGER trg_auditoria_estado_propiedad
AFTER UPDATE ON propiedades
FOR EACH ROW
BEGIN
    IF OLD.estado <> NEW.estado THEN
        INSERT INTO auditoria_propiedades (
            propiedad_id, estado_anterior, estado_nuevo, usuario_ejecutor, fecha_cambio
        ) VALUES (
            NEW.propiedad_id, OLD.estado, NEW.estado, CURRENT_USER(), CURRENT_TIMESTAMP
        );
    END IF;
END //

DROP TRIGGER IF EXISTS trg_actualizar_estado_propiedad_por_contrato //
CREATE TRIGGER trg_actualizar_estado_propiedad_por_contrato
AFTER INSERT ON contratos
FOR EACH ROW
BEGIN
    DECLARE v_nuevo_estado VARCHAR(20);

    IF NEW.tipo_contrato = 'venta' THEN
        SET v_nuevo_estado = 'vendida';
    ELSEIF NEW.tipo_contrato = 'arriendo' THEN
        SET v_nuevo_estado = 'arrendada';
    END IF;

    IF v_nuevo_estado IS NOT NULL THEN
        UPDATE propiedades
        SET estado = v_nuevo_estado
        WHERE propiedad_id = NEW.propiedad_id;

        INSERT INTO auditoria_contratos (
            contrato_id, accion, detalle, usuario_ejecutor, fecha_evento
        ) VALUES (
            NEW.contrato_id,
            'CREACION_CONTRATO',
            CONCAT('Propiedad ', NEW.propiedad_id, ' actualizada a estado ', v_nuevo_estado),
            CURRENT_USER(),
            CURRENT_TIMESTAMP
        );
    END IF;
END //

DELIMITER ;
