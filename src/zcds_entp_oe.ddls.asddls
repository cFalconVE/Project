@AbapCatalog.sqlViewName: 'ZCDS_ENTP_OE'
@AbapCatalog.compiler.CompareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Vista de las posiciones de la entrega OE'
@Metadata.ignorePropagatedAnnotations: true
@VDM.viewType: #BASIC
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view zview_entp_oe 
    as select from lips as lp //Posiciones de la Entrega
// Posiciones del pedido    
//    association[0..1] to vbap as dv  on $projection.nroPedido = dv.vbeln
//                                    and $projection.vgpos = dv.posnr
//
                                       
{
    key lp.vbeln as nroEntrega,
    key lp.posnr as posicion,
        lp.charg as nroLote,
        lp.vgbel as nroPedido,  
        lp.vgpos, 
        lp.matnr,
        lp.arktx as desMaterial,
        lp.vrkme as unidMed,
        round(lp.lfimg, 0) as cantidad,
        cast( lp.volum as abap.dec( 11, 2 ) ) as galones,
        cast( lp.brgew as abap.dec( 11, 2 ) ) as kilos,
// Precio del pedido       
//        dv.netwr,
//        case dv.netwr 
//          when 0 then 
//            cast( 0 as abap.dec( 11, 2 ) )
//          else 
//            case lp.volum
//              when 0 then
//                cast( 0 as abap.dec( 11, 2 ) )
//              else
//                division(dv.netwr, lp.volum, 2)
//             end
////            division(dv.netwr, lp.volum, 2)
//         end as precioUnitario,
        netwr,
        case netwr 
          when 0 then 
            cast( 0 as abap.dec( 11, 2 ) )
          else 
            case lp.volum
              when 0 then
                cast( 0 as abap.dec( 11, 2 ) )
              else
                division(netwr, lp.volum, 2)
             end
//            division(dv.netwr, lp.volum, 2)
         end as precioUnitario,         
         cast( 0 as abap.int1 ) as pag
//        division(dv.netwr, lp.volum, 2) as precioUnitario
//         division(netwr, lp.volum, 2) as precioUnitario
//        (lp.volum * division(dv.netwr, lp.volum, 2) ) as precioTotal
//        v_tot_price = e_vbap-netwr / e_vbap-volum.
            
} where lp.charg <> ''
