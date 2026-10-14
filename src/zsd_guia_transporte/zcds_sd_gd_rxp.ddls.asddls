@AbapCatalog.viewEnhancementCategory: [#NONE]
@AbapCatalog.sqlViewName: 'ZCDS_SD_GD_RXP'
@AbapCatalog.compiler.CompareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck:  #CHECK // #NOT_REQUIRED
@EndUserText.label: 'CDS Guia de Despacho Retiro x Planta'
@Metadata.ignorePropagatedAnnotations: true
@VDM.viewType: #BASIC
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view ZV_SD_GD_RXP
with parameters 
    p_tplst : tplst
as select from vttk as vk //Cabezado del transporte 
//as select from zsd_tb_serv_tran as t //vk //Cabezado del transporte 

//// Vista Guia de Carga
//    association[1..1] to zv_cds_sd_gc as _gc on $projection.tplst = _gc.tplst and
//                                                p_tplst = $parameters.p_tplst
                            
//Unidad Organizativa
    association [1] to ttdst as _uo on  $projection.tplst = _uo.tplst
                                       and _uo.spras = 'S'
//Clase de Transporte
    association [1] to t173t as _ct on  $projection.vsart = _ct.vsart
                                       and _ct.spras = 'S'
//Transporte
    association [1] to lfa1 as _tr on $projection.tdlnr = _tr.lifnr
//    association [1] to lfa1 as _tr on _s.rif_rxp = _tr.lifnr

// Paletas
//        association[0..1] to zview_paletas as pa on $projection.nrotrans = pa.vpobjkey
        
// Paletas que posee un tercero  (Stock especial Cliente)    
    association[0..1] to zv_pal_client as plcl on $projection.tdlnr = plcl.kunnr 
//                                                   and plcl.matnr = pa.matnr
//Gasto de transporte
    association[0..1] to vfkp as gastransp on $projection.nrotrans = gastransp.rebel
             
// Posiciones del transporte
    association [1..*] to zv_cds_gcp as _vttp on $projection.nrotrans = _vttp.nrotrans

// Ruta 
    association[1..1] to zsd_tb_serv_tran as _s on $projection.route = _s.route
    
{
//    key t.tplst,
    key vk.tknum as nrotrans, // tiene que aparecer en el detalle
    key vk.route,
        vk.datbg as femision, 
        vk.erzet as hemision,
        vk.tplst, 
        vk.vsart, 
        vk.tdlnr, 
        _s.lifnr as rif_rxp,
        _s.correo as correo_rxp,
        _s.type_serv,
//        vk.frkrl, // Indicador Gastos de Transporte
        vk.gesztd,
        cast( '' as abap.char( 20 ) ) as orddev,
        cast( '' as abap.char( 40 ) ) as ordequi,
        cast( '' as abap.char( 20 ) ) as precintos,
        cast( '' as abap.char( 20 ) ) as notcred,
        cast( '' as abap.char( 20 ) ) as despachador,
        vk.text2 as supervisor,
        vk.text3 as preparador,
        _uo.bezei as puesto,
        cast( '' as abap.char( 10 ) ) as pasevigilancia,
        cast( '' as abap.char( 40 ) ) as conductor,
        cast( '' as abap.char( 12 ) ) as ciconductor,
        cast( '' as abap.char( 20 ) ) as telefono,
        cast( '' as abap.char( 250 ) ) as correo,
        cast( '' as abap.char( 20 ) ) as placa,
        cast( '' as abap.char( 20 ) ) as estado,
        cast( '' as abap.char( 20 ) ) as ciudad,
        _ct.bezei as tipveh,
        _tr.land1 as pais,
        concat(_tr.name1, concat(' ', _tr.name2)) as transp,
        _tr.adrnr,
        cast( '' as abap.char( 50 ) ) as correotransp,
        cast( '' as abap.char( 200 ) ) as observaciones,
        cast( '' as abap.char( 20 ) ) as pesoRomana,
    //    case vk.frkrl 
    //      when 'X' then gastransp.ebeln
    //      else cast( '' as abap.char( 1 ) )
    //    end as acepservicio,
    //    case vk.frkrl 
    //      when 'X' then gastransp.lblni
    //      else cast( '' as abap.char( 1 ) )
    //    end as nrohoja, 
    //    pa.venum,
    //    pa.paleta,
    //    plcl.kulab,
        cast( 0 as abap.int1 ) as pag,
        _vttp
//    _gc
    
} where 
    vk.tplst = $parameters.p_tplst
    and ( vk.fbsta >= ' ' and
          vk.fbsta <= 'C' )
