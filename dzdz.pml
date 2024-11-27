/* ====================================================
 * Заместо пояснений нарисовал автоматы аскизными артами(:
 * Для экономии места для переходов обозначил только
 * входы.
 * ====================================================
 * LTL
 *
 *  - в системе отсутствуют дедлоки - T
 *  - кол-во правил в комке и кол-во правил
 *    в комке (с т.з. контроллера и приложения)
 *    неотрицательны - F
 * =====================================================
 * Про дедлоки
 * 
 * Был бы комп с несколькими тб оперативы 
 * и возможность ускорять время - мб контрпример
 * бы и нашелся)
 * ======================================================
 * Про правила в свитче(комке)
 *
 * Все было бы ОК если был бы чекер количества правил.
 *
 * Лог:
 * (Spin Version 6.5.2 -- 6 December 2019)
 * Warning: Search not completed
 *       + Breadth-First Search
 *
 * Full statespace search for:
 *       never claim             + (no_neg_rules)
 *       assertion violations    + (if within scope of claim)
 *       cycle checks            - (disabled by -DSAFETY)
 *       invalid end states      - (disabled by never claim)
 *
 * State-vector 116 byte, depth reached 106, errors: 1
 *   82880 states, stored
 *          57856 nominal states (- rv and atomic)
 *           3237 rvs succeeded
 *  172970 states, matched
 *  255850 transitions (= stored+matched)
 *       4 atomic steps
 * hash conflicts:       231 (resolved)
 *
 * Stats on memory usage (in Megabytes):
 *  10.750       equivalent memory usage for states (stored*(State-vector + overhead))
 *  10.231       actual memory usage for states (compression: 95.18%)
 *               state-vector as stored = 109 byte + 20 byte overhead
 * 128.000       memory used for hash table (-w24)
 * 138.156       total actual memory usage
 *
 *
 *
 * pan: elapsed time 0.08 seconds
 * pan: rate   1036000 states/second
*/

// Типы сообщений
mtype = {
    PostFlow_App, DeleteFlow_App,
    PostFlow_Cont, DeleteFlow_Cont,
    TIME_TRANSITION, 
    PostFlow_Channel1, DeleteFlow_Channel1,
    LOSS_Channel,
    ACK_Channel2,
    ACK_Switch,
}

// Каналы
chan Chan1 = [0] of {mtype}; // app/cont
chan Chan2 = [0] of {mtype}; // cont/channel1
chan Chan3 = [0] of {mtype}; // channel1
chan Chan4 = [0] of {mtype}; // channel2
chan Chan5 = [0] of {mtype}; // cont/channel2

// Начальные состояния
byte App_S = 0; byte Cont_S = 0; byte Switch_S = 0;
byte Channel1_S = 0; byte Channel2_S = 0;

/* ==================================================== 
 * Приложение
 * ==================================================== 
 *
 *
 *                                    _____     RuleContCnt <= 10
 *         :: (App_S == 0)           |     |    || RuleContCnt > 1
 * (S0) -------------------------> (S1)<---|    
 *  ^                               |           
 *  |-------------------------------|
 *          RuleContCnt == 1
 *
*/

int RuleContCnt = 0;

proctype App() {
    do
    :: (App_S == 0) ->  {
        RuleContCnt = 1;
        App_S = 1;
        Chan1!PostFlow_App;
    }
    :: (App_S == 1) -> {
        if
        :: RuleContCnt <= 10 -> {
            RuleContCnt = RuleContCnt + 1;
            Chan1!PostFlow_App;
        }
        :: RuleContCnt > 1 -> {
            RuleContCnt = RuleContCnt - 1;
            Chan1!DeleteFlow_App;
        }
        :: RuleContCnt == 1 -> {
            RuleContCnt = 0;
            Chan1!DeleteFlow_App;
            App_S = 0;
        }
        fi
    }
    od
}

/* ==================================================== 
 * Контроллер
 * ==================================================== 
 * 
 *                           
 *                 timeout  |--------------------|
 *                          v   (Cont_S == 1)    |
 *                        (S1)----------------->(S2)
 *                       /                       | MsgBuf == 
 *         PostFlow_App /                        | ACK_Channel2
 *                     / <-----------------------/
 *                 (S0)
 *                     \ <-----------------------\
 *        DeleteFlow_App\                        | MsgBuf ==
 *                       \       (Cont_S == 3)   | ACK_Channel2
 *                        (S3)----------------->(S4)
 *                          ^                    |
 *                 timeout  |--------------------|
 *
*/
proctype Cont() {
    do
    :: (Cont_S == 0) -> {
        byte MsgBuf;

        Chan1?MsgBuf
        if
        :: (MsgBuf == PostFlow_App) -> {
            Cont_S = 1;
        }
        :: (MsgBuf == DeleteFlow_App) -> {
            Cont_S = 3;
        }
        fi
    }
    :: (Cont_S == 1) -> {
        Chan2!PostFlow_Cont;
        Cont_S = 2;
    }
    :: (Cont_S == 2) -> {
        byte MsgBuf;

        do
        :: Chan5?MsgBuf -> {
            if
            :: (MsgBuf == ACK_Channel2) -> {
                Cont_S = 0;
            }
            :: (MsgBuf == LOSS_Channel) -> {
                Cont_S = 1;
            }
            fi

            break; 
        }
        :: timeout -> {
            Cont_S = 1;
            break;
        }
        ::else -> skip;
        od
    }
    :: (Cont_S == 3) -> {
        Chan2!DeleteFlow_Cont;
        Cont_S = 4;
    }
    :: (Cont_S == 4) -> {
        byte MsgBuf;

        do
        :: Chan5?MsgBuf -> {
            if
            :: (MsgBuf == ACK_Channel2) -> {
                Cont_S = 0;
            }
            :: (MsgBuf == LOSS_Channel) -> {
                Cont_S = 3;
            }
            fi

            break; 
        }
        :: timeout -> {
            Cont_S = 3;
            break;
        }
        :: else -> skip;
        od
    }
    od
}

/* ==================================================== 
 * Свитч
 * ==================================================== 
 * 
 *         (MsgBuf == 
 *        PostFlow_Channel1) 
 *        || (MsgBuf ==
 *        DeleteFlow_Channel1)         
 * (S0) -------------------------> (S1)
 *  ^                               | 
 *  |-------------------------------|
 *         :: (Switch_S == 1)
 *          
 *
*/

int RuleSwitchCnt = 0;

proctype Switch() {
    do
    :: (Switch_S == 0) -> {
        byte MsgBuf;

        Chan3?MsgBuf;
        if
        :: (MsgBuf == PostFlow_Channel1) -> {
            RuleSwitchCnt = RuleSwitchCnt + 1;
        }
        :: (MsgBuf == DeleteFlow_Channel1) -> {
            RuleSwitchCnt = RuleSwitchCnt - 1;
        }
        fi
        Switch_S = 1;
    }
    :: (Switch_S == 1) ->  {
        Switch_S = 0;
        Chan4!ACK_Switch;
    }
    od
}

/* ==================================================== 
 * Канал 1
 * ==================================================== 
 * 
 * (Channel1_S == 2)(OK)     (Channel1_S == 1)(OK)
 *  |--------------------|  |--------------------|                       
 *  |   ChanBuf ==       |  |    ChanBuf ==      |
 *  |   DeleteFlow_Cont  v  v    PostFlow_Cont   | 
 * (S2)<-----------------(S0)------------------>(S1)
 *  |                    ^  ^                    |
 *  |                    |  |                    |
 *  |--------------------|  |--------------------|
 * (Channel1_S == 2)(LOSS)   (Channel1_S == 1)(LOSS)
*/
proctype Channel1 () {
    do
    :: (Channel1_S == 0) -> {
        byte ChanBuf;

        Chan2?ChanBuf;
        if
        :: (ChanBuf == PostFlow_Cont) -> {
            Channel1_S = 1;
        }
        :: (ChanBuf == DeleteFlow_Cont) -> {
            Channel1_S = 2;
        }
        fi
    }
    :: (Channel1_S == 1) ->   {
        if 
        :: (1) ->
            Chan3!PostFlow_Channel1; // OK
        :: (1) ->
            skip; // лосс
        fi
        Channel1_S = 0;
    }
    :: (Channel1_S == 2) ->  {
        if 
        :: (1) ->
            Chan3!DeleteFlow_Channel1; // OK
        :: (1) ->
            skip; // лосс
        fi
        Channel1_S = 0;
    }
    od
}

/* ==================================================== 
 * Канал 2
 * ==================================================== 
 * 
 *    ChanBuf == ACK_Switch
 *   |--------------------|                       
 *   |                    |
 *   | Chan5!ACK_Channel2;v 
 * (S0)<----------------(S1)
 *   ^                    |
 *   |                    |
 *   |--------------------|
 *     Chan5!LOSS_Channel;
*/
proctype Channel2 () {
    do
    :: (Channel2_S == 0) -> {
        byte ChanBuf = 0;

        Chan4?ChanBuf;
        if 
        :: (ChanBuf == ACK_Switch) -> {
            Channel2_S = 1;
        }
        fi
    }
    :: (Channel2_S == 1) -> {
        if
        :: (1) ->
            Chan5!ACK_Channel2;
        :: (1) ->
            Chan5!LOSS_Channel;
        fi
        Channel2_S = 0;
    }
    od
}

// ентрипоинт
init {
    atomic {
        run App();
        run Cont();
        run Channel1();
        run Switch();
        run Channel2();
    }
}

ltl no_dlock {
    []<>(1) // always-eventually(TRUE)
}

ltl no_neg_rules {
    [](RuleContCnt >= 0 && RuleSwitchCnt >= 0) // always(notneg(RuleContCnt) && notneg(RuleSwitchCnt))
}