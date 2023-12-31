#include <Trade/Trade.mqh>
CTrade trade;

input group "Anchor Chart Indicators Settings";
input ENUM_TIMEFRAMES AC_TimeFrame = PERIOD_H1;
input ENUM_MA_METHOD AC_MaSlowType = MODE_EMA;
input ENUM_MA_METHOD AC_MaFastType = MODE_EMA;
input ENUM_APPLIED_PRICE AC_MaSlowAppliedPrice = PRICE_CLOSE;
input ENUM_APPLIED_PRICE AC_MaFastAppliedPrice = PRICE_CLOSE;
input int AC_MaSlowLength = 21;
input int AC_MaFastLength = 8;
input int AC_MaLookBack = 3;

input group "Trading Chart Indicators Settings";
input ENUM_TIMEFRAMES TC_TimeFrame = PERIOD_M5;
input ENUM_MA_METHOD TC_MaSlowType = MODE_EMA;
input ENUM_MA_METHOD TC_MaMediumType = MODE_EMA;
input ENUM_MA_METHOD TC_MaFastType = MODE_EMA;
input ENUM_APPLIED_PRICE TC_MaFastAppliedPrice = PRICE_CLOSE;
input ENUM_APPLIED_PRICE TC_MaMediumAppliedPrice = PRICE_CLOSE;
input ENUM_APPLIED_PRICE TC_MaSlowAppliedPrice = PRICE_CLOSE;
input int TC_MaSlowLength = 21;
input int TC_MaMediumLength = 13;
input int TC_MaFastLength = 8;
input int TC_MaLookBack = 5;

input group "Trading Settings";
input int PipsDifference = 3;
input double LotSize = 0.1;

double AC_MSH = iMA(_Symbol, AC_TimeFrame, AC_MaSlowLength, 0, AC_MaSlowType, AC_MaSlowAppliedPrice);
double AC_MFH = iMA(_Symbol, AC_TimeFrame, AC_MaFastLength, 0, AC_MaFastType, AC_MaFastAppliedPrice);

double TC_MFH = iMA(_Symbol, TC_TimeFrame, TC_MaFastLength, 0, TC_MaFastType, TC_MaFastAppliedPrice);
double TC_MMH = iMA(_Symbol, TC_TimeFrame, TC_MaMediumLength, 0, TC_MaMediumType, TC_MaMediumAppliedPrice);
double TC_MSH = iMA(_Symbol, TC_TimeFrame, TC_MaSlowLength, 0, TC_MaSlowType, TC_MaSlowAppliedPrice);

datetime LastAnalyzed;

int OnInit(){
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason){

}
void OnTick(){
   datetime time = iTime(_Symbol, TC_TimeFrame, 1);
   if (time != LastAnalyzed){
      CommentOnTradeType();
      PlaceOrders();
      LastAnalyzed = time;
   }
   
   
}


int DeterminTradeType(){
   double ac_ms[];
   CopyBuffer(AC_MSH, 0, 1, AC_MaLookBack, ac_ms);
   double ac_mf[];
   CopyBuffer(AC_MFH, 0, 1, AC_MaLookBack, ac_mf);
   
   if (ac_mf[AC_MaLookBack - 1] > ac_ms[AC_MaLookBack - 1]){
      double low[];
      CopyLow(_Symbol, AC_TimeFrame, 1, AC_MaLookBack, low);
      for (int i = AC_MaLookBack - 1; i >= 0; i--){
         if (low[i] <= ac_ms[i]){
            return 0;
         }
      }
      return 1;
   }
   else if (ac_mf[AC_MaLookBack - 1] < ac_ms[AC_MaLookBack - 1]){
      double high[];
      CopyHigh(_Symbol, AC_TimeFrame, 1, AC_MaLookBack, high);
      

      for (int i = AC_MaLookBack - 1; i >= 0; i--){
         if (high[i] >= ac_ms[i]){
            return 0;
         }
      }
      return 2;
   }
   else {
      return 0;
   }
}



void CommentOnTradeType(){
   int tradetypeAllowed = DeterminTradeType();
   if (tradetypeAllowed == 0){
      Comment("TRADE TYPE STATUS: NEUTRAL");
   }
   else if (tradetypeAllowed == 1){
      bool buyConfirmed = ConfirmTrendBuy();
      
      Comment("\nTRADE TYPE STATUS: ", "BUY",
              "\nTrend Confirmed: ", buyConfirmed);
   }
   else if (tradetypeAllowed == 2){
      bool sellConfirmed = ConfirmTrendSell();
      Comment("\nTRADE TYPE STATUS: ", "SELL",
              "\nTrend Confirmed: ", sellConfirmed);
   }
}

bool ConfirmTrendBuy(){
   double tc_ms[];
   CopyBuffer(TC_MSH, 0, 1, TC_MaLookBack, tc_ms);
   double tc_mm[];
   CopyBuffer(TC_MMH, 0, 1, TC_MaLookBack, tc_mm);
   double tc_mf[];
   CopyBuffer(TC_MFH, 0, 1, TC_MaLookBack, tc_mf);
   
   double low[];
   CopyLow(_Symbol, TC_TimeFrame, 1, TC_MaLookBack, low);
      
   for (int i = TC_MaLookBack - 1; i >= 0; i--){
      if (tc_mf[i] < tc_mm[i]){
         return false;
      }
      else if (tc_mm[i] < tc_ms[i]){
         return false;
      }
      else if (tc_mf[i] < tc_ms[i]){
         return false;
      }
      else if (low[i] < tc_ms[i]){
         return false;
      }
      
   }
   return true;
}

bool ConfirmTrendSell(){
   double tc_ms[];
   CopyBuffer(TC_MSH, 0, 1, TC_MaLookBack, tc_ms);
   double tc_mm[];
   CopyBuffer(TC_MMH, 0, 1, TC_MaLookBack, tc_mm);
   double tc_mf[];
   CopyBuffer(TC_MFH, 0, 1, TC_MaLookBack, tc_mf);
   
   double high[];
   CopyHigh(_Symbol, TC_TimeFrame, 1, TC_MaLookBack, high);
      
   for (int i = TC_MaLookBack - 1; i >= 0; i--){
      if (tc_mf[i] > tc_mm[i]){
         return false;
      }
      else if (tc_mm[i] > tc_ms[i]){
         return false;
      }
      else if (tc_mf[i] > tc_ms[i]){
         return false;
      }
      else if (high[i] > tc_ms[i]){
         return false;
      }
      
   }
   return true;
}

bool BuyOrderTrigger(){
   double tc_ms[];
   CopyBuffer(TC_MSH, 0, 1, 1, tc_ms);
   double tc_mm[];
   CopyBuffer(TC_MMH, 0, 1, 1, tc_mm);
   double tc_mf[];
   CopyBuffer(TC_MFH, 0, 1, 1, tc_mf);
   
   double low[];
   CopyLow(_Symbol, TC_TimeFrame, 1, 1, low);
   double close[];
   CopyClose(_Symbol, TC_TimeFrame, 1, 1, close);
   
   if (low[0] <= tc_mf[0] && close[0] > tc_ms[0]){
         return true;
   }
   else {
      return false;
   }
}

bool SellOrderTrigger(){
   double tc_ms[];
   CopyBuffer(TC_MSH, 0, 1, 1, tc_ms);
   double tc_mm[];
   CopyBuffer(TC_MMH, 0, 1, 1, tc_mm);
   double tc_mf[];
   CopyBuffer(TC_MFH, 0, 1, 1, tc_mf);
   
   double high[];
   CopyHigh(_Symbol, TC_TimeFrame, 1, 1, high);
   double close[];
   CopyClose(_Symbol, TC_TimeFrame, 1, 1, close);
   
   if (high[0] >= tc_mf[0] && close[0] < tc_mm[0]){
      return true;
   }
   else {
      return false;
   }
}

void PlaceBuyOrder(){
   double high[];
   CopyHigh(_Symbol, TC_TimeFrame, 1, TC_MaLookBack, high);
   double low[];
   CopyLow(_Symbol, TC_TimeFrame, 1, TC_MaLookBack, low);
   
   double highest;
   for (int i = TC_MaLookBack - 1; i>=0; i--){
      if (high[i] > highest){
         highest = high[i];
      }
   }
   double entry = highest + PipsDifference * _Point;
   double sl = low[TC_MaLookBack - 1] - PipsDifference * _Point;
   double distance = entry - sl;
   double tp = entry + distance;
   
   //double entry = highest;
   //double sl = low[TC_MaLookBack - 1];
   //double distance = entry - sl;
   //double tp = entry + distance;
   Print("Buy Order | Entry: "+entry+" | "+"Sl: "+sl+" | "+" Distance: "+distance+" | "+"TP: "+tp);

   trade.BuyStop(LotSize, entry, _Symbol, sl, tp);
}

void PlaceSellOrder(){
   double high[];
   CopyHigh(_Symbol, TC_TimeFrame, 1, TC_MaLookBack, high);
   double low[];
   CopyLow(_Symbol, TC_TimeFrame, 1, TC_MaLookBack, low);
   
   double lowest;
   for (int i = TC_MaLookBack - 1; i>=0; i--){
      if (low[i] < lowest){
         lowest = low[i];
      }
   }
   double entry = lowest - PipsDifference * _Point;
   double sl = high[TC_MaLookBack - 1] + PipsDifference * _Point;
   double distance = sl - entry;
   double tp = entry - distance;
   
   //double entry = lowest;
   //double sl = high[TC_MaLookBack - 1];
   //double distance = sl - entry;
   //double tp = entry - distance;
   Print("Sell Order | Entry: "+entry+" | "+"Sl: "+sl+" | "+" Distance: "+distance+" | "+"TP: "+tp);
   trade.SellStop(LotSize, entry, _Symbol, sl, tp);
}

void PlaceOrders(){
   int tradetypeAllowed = DeterminTradeType();
   if (tradetypeAllowed == 1){
      bool buyConfirmed = ConfirmTrendBuy();
      if (buyConfirmed){
         bool buyTrigger = BuyOrderTrigger();
         if (buyTrigger){
            PlaceBuyOrder();
         }
      }
   }
   else if (tradetypeAllowed == 2){
      bool sellConfirmed = ConfirmTrendSell();
      if (sellConfirmed){
         bool sellTrigger = SellOrderTrigger();
         if (sellTrigger){
            PlaceSellOrder();
         }
      }
   }
}