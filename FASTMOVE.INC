TOP:    FILD    QWORD PTR [ESI]                                                 
        FILD    QWORD PTR [ESI+8]                                               
        FXCH                                                                    
        FISTP   QWORD PTR [EDI]                                                 
        FISTP   QWORD PTR [EDI+8]                                               
        ADD     ESI, 16                                                         
        ADD     EDI, 16                                                         
        DEC     ECX                                                             
        JNZ     TOP                                                             
                                                                                
