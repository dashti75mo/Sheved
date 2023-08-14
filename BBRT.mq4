
#property copyright "Copyright 2022, Moj.DS"
#property link      "https://www.LevelUP.com"
#property version   "1.31"
#property description "Signals Is Beta Testing,Signals Based On RSI and BBands and PriceAction,Now You Can Change Values In Setting IMPORTANT: Adjust Thersholdsetting can be obtained from ATR/2Days ago price changes/manual in setting higher for GOLD & Brent and FOR Currency Pairs 0.0001 "
#include <stdlib.mqh>
#include <stderror.mqh>
string ExpiryDate = "2023.10.30";
//--- indicator settings
#property indicator_chart_window
#property indicator_buffers 4

#property indicator_type1 DRAW_ARROW
#property indicator_width1 4
#property indicator_color1 0xFFAA00
#property indicator_label1 "Buy"

#property indicator_type2 DRAW_ARROW
#property indicator_width2 4
#property indicator_color2 0xFF00F7
#property indicator_label2 "Buy"

#property indicator_type3 DRAW_ARROW
#property indicator_width3 4
#property indicator_color3 0x0000FF
#property indicator_label3 "Sell"

#property indicator_type4 DRAW_ARROW
#property indicator_width4 4
#property indicator_color4 0x00A6FF
#property indicator_label4 "Sell"

//--- indicator buffers
double Buffer1[];
double Buffer2[];
double Buffer3[];
double Buffer4[];


// ... (Previous code remains the same)
//--- input parameters
input int RSIPeriod = 14;         // Value Of RSI
input int BbandValue = 20;        // Value of Bollinger Bands
input int Deviations = 2;         // Bollinger Bands Deviations
input bool RSIValidation = false; // Enable or disable Validation Check of RSIValue
input bool UseATR = false;        // Enable or disable the use of ATR
input int ATRPeriod = 14;        // ATR period for calculating the adaptive threshold
input double atrMultiplier = 2.0; // Multiplier for the adaptive threshold
input bool UseAutoThreshold = true; // Enable or disable automatic calculation of fixed threshold
double FixedThreshold = 0.0150; // Default threshold value
input bool ManualThreshold = false; // Enable or disable manual input of fixed threshold
input double FixedThresholdValue = 0.0150; // Custom value for the fixed threshold
//...

datetime time_alert; // Used when sending alerts
bool Send_Email = true;
bool Audible_Alerts = true;
bool Push_Notifications = true;
double myPoint; // Initialized in OnInit
double currentATR; // ATR value for the current bar

void myAlert(string type, string message)
  {
   int handle;
   if(type == "print")
      Print(message);
   else if(type == "error")
     {
      Print(type+" | BBRT @ "+Symbol()+","+IntegerToString(Period())+" | "+message);
     }
   else if(type == "order")
     {
     }
   else if(type == "modify")
     {
     }
   else if(type == "indicator")
     {
      Print(type+" | BBRT @ "+Symbol()+","+IntegerToString(Period())+" | "+message);
      if(Audible_Alerts) Alert(type+" | BBRT @ "+Symbol()+","+IntegerToString(Period())+" | "+message);
      if(Send_Email) SendMail("BBRT", type+" | BBRT @ "+Symbol()+","+IntegerToString(Period())+" | "+message);
      handle = FileOpen("BBRT.txt", FILE_TXT|FILE_READ|FILE_WRITE|FILE_SHARE_READ|FILE_SHARE_WRITE, ';');
      if(handle != INVALID_HANDLE)
        {
         FileSeek(handle, 0, SEEK_END);
         FileWrite(handle, type+" | BBRT @ "+Symbol()+","+IntegerToString(Period())+" | "+message);
         FileClose(handle);
        }
      if(Push_Notifications) SendNotification(type+" | BBRT @ "+Symbol()+","+IntegerToString(Period())+" | "+message);
     }
  }

string messageBoxText = ""; // Variable to hold the message text
int messageBoxLabel; // Object ID of the message box

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
    // Validity Check
    if (TimeCurrent() >= StrToTime(ExpiryDate))
    {
        Alert("Indicator Needs Update, Contact Author");
        return (0);
    }
    else
    {
        Print("Indicator is Valid and Latest Version v1.31");
    }

    // Indicator Buffers
    IndicatorBuffers(4);
    SetIndexBuffer(0, Buffer1);
    SetIndexEmptyValue(0, EMPTY_VALUE);
    SetIndexArrow(0, 241);
    SetIndexBuffer(1, Buffer2);
    SetIndexEmptyValue(1, EMPTY_VALUE);
    SetIndexArrow(1, 241);
    SetIndexBuffer(2, Buffer3);
    SetIndexEmptyValue(2, EMPTY_VALUE);
    SetIndexArrow(2, 242);
    SetIndexBuffer(3, Buffer4);
    SetIndexEmptyValue(3, EMPTY_VALUE);
    SetIndexArrow(3, 242);

    // Initialize myPoint
    myPoint = Point();
    if (Digits() == 5 || Digits() == 3)
    {
        myPoint *= 10;
    }

    if (UseAutoThreshold && !ManualThreshold)
    {
        FixedThreshold = calculateFixedThreshold(); // Calculate the fixed threshold based on historical data
    }
    else if (ManualThreshold)
    {
        FixedThreshold = FixedThresholdValue; // Use the custom value for the fixed threshold
    }


    return (INIT_SUCCEEDED);
}


int calculateFixedThreshold()
{
    double sumRange = 0.0;
    int numBars = 0;

    for (int i = 0; i < 2; i++) // Loop through the last 2 days
    {
        double highLowRange = High[i] - Low[i];
        sumRange += highLowRange;
        numBars++;
    }
     Comment("SystemDecidedThershouldvalue=",(double)(sumRange / numBars / myPoint));
    if (numBars > 0)
        return (double)(sumRange / numBars / myPoint); // Calculate the average range and convert it to points
        
    else
        return 15; // Default value if no valid data found
}


//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
    int limit = rates_total - prev_calculated;

    //--- counting from 0 to rates_total
    ArraySetAsSeries(Buffer1, true);
    ArraySetAsSeries(Buffer2, true);
    ArraySetAsSeries(Buffer3, true);
    ArraySetAsSeries(Buffer4, true);

    //--- initial zero
    if (prev_calculated < 1)
    {
        ArrayInitialize(Buffer1, EMPTY_VALUE);
        ArrayInitialize(Buffer2, EMPTY_VALUE);
        ArrayInitialize(Buffer3, EMPTY_VALUE);
        ArrayInitialize(Buffer4, EMPTY_VALUE);
    }
    else
        limit++;

    //--- main loop
    for (int i = limit - 1; i >= 0; i--)
    {
          if (i >= MathMin(5000-1, rates_total-1-50)) continue; //omit some old rates to prevent "Array out of range" or slow calculation   

        // Calculate ATR
        currentATR = iATR(NULL, 0, ATRPeriod, i);

        // Calculate RSI
        double rsi1 = iRSI(NULL, 0, RSIPeriod, PRICE_CLOSE, i);
        double rsi2 = iRSI(NULL, 0, RSIPeriod, PRICE_CLOSE, i + 1);
        double rsi3 = iRSI(NULL, 0, RSIPeriod, PRICE_CLOSE, i + 2);

        double threshold;
        if (UseATR)
        {
            threshold = atrMultiplier * currentATR;
        }
        else if (ManualThreshold)
        {
            threshold = FixedThreshold * myPoint;
        }
        else
        {
            threshold = calculateFixedThreshold() * myPoint;
        }
        // Indicator Buffer 1 (Buy)
        if (iBands(NULL, PERIOD_CURRENT, BbandValue, Deviations, 0, PRICE_LOW, MODE_LOWER, i) < open[1 + i] &&
            iBands(NULL, PERIOD_CURRENT, BbandValue, Deviations, 0, PRICE_LOW, MODE_LOWER, i + 1) > open[1 + i + 1] && // Bollinger Bands crosses below Candlestick Open
            close[i + 1] > open[i + 1] && close[i + 2] < open[i + 2] && close[i + 2] < open[i + 1] && open[i + 2] > close[i + 1] &&
            (!RSIValidation || (rsi1 < 30 && rsi2 < 30 && rsi3 < 30)))
        {
            Buffer1[i] = open[i + 1]; // Set indicator value at Candlestick Open
            if (i == 0 && Time[0] != time_alert)
            {
                myAlert("indicator", "Buy");
                time_alert = Time[0]; // Instant alert, only once per bar
            }
        }
        else
        {
            Buffer1[i] = EMPTY_VALUE;
        }

        // Indicator Buffer 2 (Buy)
        if (iBands(NULL, PERIOD_CURRENT, BbandValue, Deviations, 0, PRICE_LOW, MODE_LOWER, i) < open[1 + i] &&
            iBands(NULL, PERIOD_CURRENT, BbandValue, Deviations, 0, PRICE_LOW, MODE_LOWER, i + 1) > open[1 + i + 1] && // Bollinger Bands crosses below Candlestick Open
            MathAbs(iBands(NULL, PERIOD_CURRENT, BbandValue, Deviations, 0, PRICE_LOW, MODE_LOWER, i) - iBands(NULL, PERIOD_CURRENT, BbandValue, Deviations, 0, PRICE_LOW, MODE_LOWER, i + 1)) < threshold &&
            (!RSIValidation || (rsi1 < 30 && rsi2 < 30 && rsi3 < 30)))
        {
            Buffer2[i] = low[i + 1]; // Set indicator value at Candlestick Low
            if (i == 0 && Time[0] != time_alert)
            {
                myAlert("indicator", "Buy");
                time_alert = Time[0]; // Instant alert, only once per bar
            }
        }
        else
        {
            Buffer2[i] = EMPTY_VALUE;
        }

        // Indicator Buffer 3 (Sell)
        if (iBands(NULL, PERIOD_CURRENT, BbandValue, Deviations, 0, PRICE_HIGH, MODE_UPPER, i) > open[i] &&
            iBands(NULL, PERIOD_CURRENT, BbandValue, Deviations, 0, PRICE_HIGH, MODE_UPPER, i + 1) < open[i + 1] && // Bollinger Bands crosses above Candlestick Open
            MathAbs(iBands(NULL, PERIOD_CURRENT, BbandValue, Deviations, 0, PRICE_HIGH, MODE_UPPER, i) - iBands(NULL, PERIOD_CURRENT, BbandValue, Deviations, 0, PRICE_HIGH, MODE_UPPER, i + 1)) > threshold &&
            (!RSIValidation || (rsi1 > 70 && rsi2 > 70 && rsi3 > 70)))
        {
            Buffer3[i] = open[i + 1]; // Set indicator value at Candlestick Open
            if (i == 0 && Time[0] != time_alert)
            {
                myAlert("indicator", "Sell");
                time_alert = Time[0]; // Instant alert, only once per bar
            }
        }
        else
        {
            Buffer3[i] = EMPTY_VALUE;
        }

        // Indicator Buffer 4 (Sell)
        if (iBands(NULL, PERIOD_CURRENT, BbandValue, Deviations, 0, PRICE_CLOSE, MODE_UPPER, i) > open[i] &&
            iBands(NULL, PERIOD_CURRENT, BbandValue, Deviations, 0, PRICE_CLOSE, MODE_UPPER, i + 1) < open[i + 1] && // Bollinger Bands crosses above Candlestick Open
            close[i + 1] < open[i + 1] && close[i + 2] > open[i + 2] && close[i + 2] > open[i + 1] && open[i + 2] < close[i + 1] &&
            (!RSIValidation || (rsi1 > 70 && rsi2 > 70 && rsi3 > 70)))
        {
            Buffer4[i] = open[i + 1]; // Set indicator value at Candlestick Open
            if (i == 0 && Time[0] != time_alert)
            {
                myAlert("indicator", "Sell");
                time_alert = Time[0]; // Instant alert, only once per bar
            }
        }
        else
        {
            Buffer4[i] = EMPTY_VALUE;
        }
    }

    return rates_total;
}
