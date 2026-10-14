@AbapCatalog.sqlViewName: 'ZCDS_ENTREGA_DEV'
@AbapCatalog.compiler.CompareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Vista Devolución de Materiales OE'
@Metadata.ignorePropagatedAnnotations: true
@VDM.viewType: #BASIC
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view zview_entrega_dev 
//as select from data_source_name
    with parameters
        p_tplst : tplst
    as 
    select from vttk as vk
      
// Posiciones del Transporte
    association[1] to zview_enr_po_oe as _vp on $projection.nrotransporte = _vp.nroTransporte

// Organización
    association[1] to zview_org_vtas as _ov on $projection.orgVta = _ov.orgVtas
   
//Clase de Transporte
    association [1] to t173t as _ct on $projection.vsart = _ct.vsart
                                   and _ct.spras = 'S' 
{
    key vk.tplst as orgVta,
    key vk.tknum as nrotransporte,
        cast( '' as abap.char( 10 ) ) as nroTranOri,
        vk.tdlnr,
        vk.frkrl as indGasTrans,
        vk.vsart,
        _vp.nroEntrega,
        _vp.isImprimir,
        _vp.lfart,
        _vp.nroPedido,
        _vp.waerk,        
        _vp.nroPosiciones,
        _ov.rif,
        _ov.razonSocial,
        _ov.dir1,
        _ov.dir2,
        _ov.dir3,
        _ov.pais,
        _ov.ciudad,
        _ov.paisCiudad,
        _ov.telefono,
        cast( '' as abap.char( 50 ) ) as correoDestino,
        cast( '' as abap.char( 50 ) ) as correo,
        cast( '' as abap.char( 40 ) ) as transporte,
        cast( '' as abap.char( 10 ) ) as nroPlaca,
        _vp.kunnr,
        _vp.kunag,
        cast( '' as abap.char( 160 ) ) as diReceptor,
        cast( '' as abap.char( 80 ) ) as observaciones,
        cast( 0 as abap.int1 ) as pag,
        cast( '' as abap.char( 1 ) ) as status,
// Vistas y tablas asociadas        
        _vp
        
} where vk.tplst = $parameters.p_tplst
    and ( _vp.lfart = 'LR' )
