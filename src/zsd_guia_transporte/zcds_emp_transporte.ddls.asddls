@AbapCatalog.sqlViewName: 'ZVIEW_EMP_TRANSP'
@AbapCatalog.compiler.CompareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Empresas transportistas'
@Metadata.ignorePropagatedAnnotations: true
@VDM.viewType: #BASIC
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view zv_emp_transporte 
    as select from zsd_tb_drivers as dr
// Comunicaciones del transportista    
    association[1] to zv_com_transp as _tr on $projection.carrier_code = _tr.lifnr
{
    key  dr.carrier_code,
        _tr.name1,
        _tr.remark,
        _tr.tel_number,
        _tr.smtp_addr,
        _tr.types,
        _tr.deletetype,
        _tr
}
group by dr.carrier_code, _tr.name1, _tr.remark, _tr.tel_number, _tr.smtp_addr, _tr.types, _tr.deletetype
