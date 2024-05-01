class ZCL_ZJFB_OV_DPC_EXT definition
  public
  inheriting from ZCL_ZJFB_OV_DPC
  create public .

public section.
protected section.

  methods MENSAGEMSET_CREATE_ENTITY
    redefinition .
  methods MENSAGEMSET_DELETE_ENTITY
    redefinition .
  methods OVCABSET_CREATE_ENTITY
    redefinition .
  methods OVCABSET_GET_ENTITYSET
    redefinition .
  methods OVITEMSET_CREATE_ENTITY
    redefinition .
  methods OVITEMSET_GET_ENTITYSET
    redefinition .
private section.
ENDCLASS.



CLASS ZCL_ZJFB_OV_DPC_EXT IMPLEMENTATION.


  method MENSAGEMSET_CREATE_ENTITY.

  endmethod.


  method MENSAGEMSET_DELETE_ENTITY.

  endmethod.


  METHOD ovcabset_create_entity.

    DATA: ld_lastid TYPE int4.
    DATA: ls_cab    TYPE zjfb_ovcab.

    DATA(lo_msg) = me->/iwbep/if_mgw_conv_srv_runtime~get_message_container( ).

    io_data_provider->read_entry_data(
      IMPORTING
        es_data = er_entity
    ).

    MOVE-CORRESPONDING er_entity TO ls_cab.

    ls_cab-criacao_data    = sy-datum.
    ls_cab-criacao_hora    = sy-uzeit.
    ls_cab-criacao_usuario = sy-uname.

    SELECT SINGLE MAX( ordemid )
      INTO ld_lastid
      FROM zjfb_ovcab.

    ls_cab-ordemid = ld_lastid + 1.
    INSERT zjfb_ovcab FROM ls_cab.
    IF sy-subrc <> 0.
      lo_msg->add_message_text_only(
        EXPORTING
          iv_msg_type = 'E'
          iv_msg_text = 'Erro ao inserir ordem'
      ).

      RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
        EXPORTING
          message_container = lo_msg.
    ENDIF.

    " atualizando
    MOVE-CORRESPONDING ls_cab TO er_entity.

    CONVERT
      DATE ls_cab-criacao_data
      TIME ls_cab-criacao_hora
      INTO TIME STAMP er_entity-datacriacao
      TIME ZONE sy-zonlo.

  ENDMETHOD.


  METHOD ovitemset_create_entity.

    DATA: ls_item TYPE zjfb_ovitem.

    DATA(lo_msg) = me->/iwbep/if_mgw_conv_srv_runtime~get_message_container( ).

    io_data_provider->read_entry_data(
      IMPORTING
        es_data = er_entity
    ).

    MOVE-CORRESPONDING er_entity TO ls_item.

    IF er_entity-itemid = 0.
      SELECT SINGLE MAX( itemid )
        INTO er_entity-itemid
        FROM zjfb_ovitem
       WHERE ordemid = er_entity-ordemid.

      er_entity-itemid = er_entity-itemid + 1.
    ENDIF.

    INSERT zjfb_ovitem FROM ls_item.
    IF sy-subrc <> 0.
      lo_msg->add_message_text_only(
        EXPORTING
          iv_msg_type = 'E'
          iv_msg_text = 'Erro ao inserir item'
      ).

      RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
        EXPORTING
          message_container = lo_msg.
    ENDIF.

  ENDMETHOD.


  METHOD ovcabset_get_entityset.

    DATA: lt_cab       TYPE STANDARD TABLE OF zjfb_ovcab.
    DATA: ls_cab       TYPE zjfb_ovcab.
    DATA: ls_entityset LIKE LINE OF et_entityset.

*    DATA: lt_orderby   TYPE STANDARD TABLE OF string.
*    DATA: ld_orderby   TYPE string.
*
*    " montando orderby dinâmico
*    LOOP AT it_order INTO DATA(ls_order).
*      TRANSLATE ls_order-property TO UPPER CASE.
*      TRANSLATE ls_order-order TO UPPER CASE.
*      IF ls_order-order = 'DESC'.
*        ls_order-order = 'DESCENDING'.
*      ELSE.
*        ls_order-order = 'ASCENDING'.
*      ENDIF.
*      APPEND |{ ls_order-property } { ls_order-order }|
*          TO lt_orderby.
*    ENDLOOP.
*    CONCATENATE LINES OF lt_orderby INTO ld_orderby SEPARATED BY ''.
*
*    " ordenação obrigatória caso nenhuma seja definida
*    IF ld_orderby = '' .
*      ld_orderby = 'OrdemId ASCENDING'.
*    ENDIF.
*
*    SELECT *
*      FROM zjfb_ovcab
*     WHERE (iv_filter_string)
*  ORDER BY (ld_orderby)
*      INTO TABLE @lt_cab
*     UP TO @is_paging-top ROWS
*    OFFSET @is_paging-skip.

    SELECT *
      INTO TABLE lt_cab
      FROM zjfb_ovcab.

    LOOP AT lt_cab INTO ls_cab.
      CLEAR ls_entityset.
      MOVE-CORRESPONDING ls_cab TO ls_entityset.

      ls_entityset-criadopor = ls_cab-criacao_usuario.

      CONVERT DATE ls_cab-criacao_data
              TIME ls_cab-criacao_hora
         INTO TIME STAMP ls_entityset-datacriacao
         TIME ZONE sy-zonlo.

      APPEND ls_entityset TO et_entityset.
    ENDLOOP.

  ENDMETHOD.


  METHOD ovitemset_get_entityset.

    DATA: ld_ordemid       TYPE int4.
    DATA: lt_ordemid_range TYPE RANGE OF int4.
    DATA: ls_ordemid_range LIKE LINE OF lt_ordemid_range.
    DATA: ls_key_tab       LIKE LINE OF it_key_tab.

    " input
    READ TABLE it_key_tab INTO ls_key_tab WITH KEY name = 'OrdemId'.
    IF sy-subrc = 0.
      ld_ordemid = ls_key_tab-value.

      CLEAR ls_ordemid_range.
      ls_ordemid_range-sign   = 'I'.
      ls_ordemid_range-option = 'EQ'.
      ls_ordemid_range-low    = ld_ordemid.
      APPEND ls_ordemid_range TO lt_ordemid_range.
    ENDIF.

    SELECT *
      INTO CORRESPONDING FIELDS OF TABLE et_entityset
      FROM zjfb_ovitem
     WHERE ordemid IN lt_ordemid_range.

  ENDMETHOD.
ENDCLASS.
