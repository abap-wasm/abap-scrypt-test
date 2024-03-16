CLASS zcl_scrypt_test_logic DEFINITION PUBLIC.
  PUBLIC SECTION.
    CLASS-METHODS run RAISING zcx_wasm.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_scrypt_test_logic IMPLEMENTATION.


  METHOD run.

    DATA(lv_base64) = zcl_scrypt_test_data=>get_optimized( ).

    DATA(li_wasm) = zcl_wasm=>create_with_base64(
      iv_base64  = lv_base64
      it_imports = VALUE #( (
        name   = '__wbindgen_placeholder__'
        module = NEW zcl_scrypt_test_placeholder( ) ) ) ).
    GET RUN TIME FIELD DATA(lv_end).

    DATA(lt_results) = li_wasm->execute_function_export(
      iv_name       = '__wbindgen_add_to_stack_pointer'
      it_parameters = VALUE #( ( zcl_wasm_i32=>from_signed( -16 ) ) ) ).
    DATA(lo_retptr) = CAST zcl_wasm_i32( lt_results[ 1 ] ).

    TRY.
        lt_results = li_wasm->execute_function_export(
          iv_name       = 'run'
          it_parameters = VALUE #( ( lo_retptr ) ) ).
        LOOP AT lt_results INTO DATA(li_result).
          WRITE / |{ li_result->get_type( ) }: { li_result->human_readable_value( ) }|.
        ENDLOOP.

        DATA(li_linear) = li_wasm->get_memory( )->get_linear( ).
        DATA(lv_realptr) = li_linear->get(
          iv_length = 4
          iv_offset = lo_retptr->get_signed( ) ).
        " WRITE / lv_realptr.

        DATA(lv_reallen) = li_linear->get(
          iv_length = 4
          iv_offset = lo_retptr->get_signed( ) + 4 ).
        " WRITE / lv_reallen.

        DATA(lv_return) = li_linear->get(
          iv_length = CONV #( lv_reallen )
          iv_offset = CONV #( lv_realptr ) ).
        DATA(lv_expected) = |Hello 636d8985f1148f8a10f9f925f4e3e895b867bdf43a8f796fc8c49926406519fae4a29b2e492f76ce3b0bd96143264b04ee86decf16f9c1396d4de96ea453b8a2|.
        DATA(lv_str) = cl_abap_codepage=>convert_from( zcl_wasm_binary_stream=>reverse_hex( lv_return ) ).
        WRITE / lv_str.
        ASSERT lv_expected = lv_str.
      CATCH zcx_wasm INTO DATA(lo_exception).
        WRITE / |Exception: { lo_exception->get_text( ) } |.
    ENDTRY.

  ENDMETHOD.
ENDCLASS.
