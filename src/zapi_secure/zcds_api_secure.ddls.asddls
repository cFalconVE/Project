@AbapCatalog.sqlViewName: 'ZVIEW_api'
@AbapCatalog.compiler.CompareFilter: true
@AbapCatalog.preserveKey: true
@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Consulta Api asociada a los Servicios de API REST'
@Metadata.ignorePropagatedAnnotations: true
@VDM.viewType: #BASIC
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view zv_api_key
    with parameters
        p_bukrs : bukrs,
        p_servicio : zservicio 
    as select from zap_host_apik as k

// Posiciones
    association[1..1] to zap_host_apip as _p on k.uuid = _p.uuid_k
                                               
{
    key k.uuid,
    key k.bukrs,
    key servicio,
    key valor as dato,
    erdat as fecha,
    descripcion,
    dominio,
    host_ip as ip,
    activo,
    erzet as hora,
//    _p.uuid_k as fk,
    _p.api_key,
    _p.cipher,
    _p.fecha_alta,    
    _p.fecha_expira,
    _p
}
where k.bukrs = $parameters.p_bukrs and
      k.servicio = $parameters.p_servicio
