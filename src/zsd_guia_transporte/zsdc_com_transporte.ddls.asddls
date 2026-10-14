@AbapCatalog.sqlViewName: 'ZVIEW_COM_TRANSP'
@AbapCatalog.compiler.CompareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Comunicaciones del Transportista'
@Metadata.ignorePropagatedAnnotations: true
@VDM.viewType: #BASIC
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view zv_com_transp 
    as select from lfa1 as cl
// Telefono de contacto    
    association[0..1] to adr2 as _t on $projection.adrnr = _t.addrnumber and
                                       _t.flgdefault = 'X'
// Nombre del Contacto    
    association[0..1] to adrt as _co  on $projection.adrnr = _co.addrnumber and 
                                         _co.langu = 'S' and
                                         _co.comm_type = 'TEL' and
                                         _co.consnumber = '001'
// Correo del Contacto del Transportista    
    association[0..1] to adr6 as _e on $projection.adrnr = _e.addrnumber and
                                       _e.flgdefault = 'X' and
                                       _e.persnumber = ''
//  Operadores Logísticos / Planta
    association[0..1] to zsd_tb_serv_tran as _op on $projection.lifnr = _op.lifnr
{
    key lifnr,
    key adrnr,
        name1,
        _t.tel_number,
        _co.remark,
        case lifnr
            when 'J000295727' then
               _op.correo
            else
               _e.smtp_addr
        end as smtp_addr,
        _op.type_serv,
        case _op.type_serv
            when 'D' then
                cast( 'distributor' as abap.char( 15 ) ) 
            when 'P' then
                cast( 'planta' as abap.char( 15 ) ) 
            when 'T' then
                cast( 'transporter' as abap.char( 15 ) )
        end as types,
        case _op.activo
            when '' then
            case _op.type_serv
                when 'D' then
                    cast( 'distributor' as abap.char( 15 ) ) 
                when 'P' then
                    cast( 'Planta' as abap.char( 15 ) ) 
                when 'T' then
                    cast( 'transporter' as abap.char( 15 ) )
            end
        end as deletetype,
        _op.route,
        _t,
        _co,
        _e,
        _op
}
//where _t.flgdefault = 'X' and
//     _co.comm_type = 'TEL' and
//     _co.consnumber = '001' and
//     _e.flgdefault = 'X' and
//     _e.persnumber = ''
