'
'
' BSD 3-Clause License
' Copyright (c) 2018, Iain Staffell
' All rights reserved.
' See license text at the bottom of this script..
'
'
' MENU:
'
' * Bansenshukai()
'
'   Run solar PV simulation and download results into the active worksheet
'
'   Requires the following named ranges to exist (defined at worksheet or workbook level)
'   - for model inputs:
'     TOKEN, DATASET, YEAR, LON, LAT, CAPACITY, AGGREGATION, SYSTEM_LOSS, TRACKING, TILT, AZIMUTH
'   - for writing model results:
'     OUTPUT
'
'
'
' * Shoninki()
'
'   Run wind simulation and download results into the active worksheet
'
'   Requires the following named ranges to exist (defined at worksheet or workbook level)
'   - for model inputs:
'     TOKEN, DATASET, YEAR, LON, LAT, CAPACITY, AGGREGATION, HEIGHT, TURBINE
'   - for writing model results:
'     OUTPUT
'
' 
'
' * Ninpiden(Url, Par, Tok)
'
'   Background function to communicate with the renewables.ninja API
'   Takes three parameters:
'      Url = the base address of the API model
'      Par = a string containing the parameters to pass to the model
'      Tok = the string containing the user token
'   Returns an array of strings (the rows of CSV data)
'
'


' DOWNLOAD SOLAR DAILY DATA
Sub Bansenshukai()
    
    
    
    '''
    '''  READ IN PARAMETERS
    '''
    
          Tok = Range("TOKEN")
      dataset = Range("DATASET")
    date_from = Range("YEAR") & "-01-01"
      date_to = Range("YEAR") & "-12-31"
          lon = Range("LON")
          lat = Range("LAT")
     capacity = Range("CAPACITY")
     aggregat = Range("AGGREGATION")
     
         loss = Range("SYSTEM_LOSS")
        track = Range("TRACKING")
         tilt = Range("TILT")
      azimuth = Range("AZIMUTH")
    
    
    
    '''
    '''  BUILD THE REQUEST URL
    '''
        
    Url = "https://www.renewables.ninja/api/data/pv?"
    
    Par = "lat=" & lat & "&lon=" & lon & "&date_from=" & date_from & "&date_to=" & date_to & _
          "&dataset=" & dataset & "&capacity=" & capacity & "&system_loss=" & loss & _
          "&tracking=" & track & "&tilt=" & tilt & "&azim=" & azimuth & "&format=csv"
    
    If (aggregat <> "hour") Then Par = Par & "&mean=" & aggregat


    ' set a warning that we're updating
    Range("OUTPUT").Select
    With Range(Selection, Selection.Offset(0, 1)).Interior
        .ThemeColor = xlThemeColorAccent2
        .TintAndShade = 0.7
    End With
    
   
    
    '''
    '''  RUN API SIMULATION & DOWNLOAD DATA
    '''

    csv = Ninpiden(Url, Par, Tok)



    '''
    '''  PASTE INTO SPREADSHEET
    '''
   
   If Not (IsEmpty(csv)) Then
        
        ' spit it into the workbook
        Range("OUTPUT").Offset(1).Select
        Range(ActiveCell, ActiveCell.Offset(UBound(csv))).Value = Application.Transpose(csv)
    
        ' set a clear signal
        Range("OUTPUT").Select
        With Range(Selection, Selection.Offset(0, 1)).Interior
            .ThemeColor = xlThemeColorAccent3
            .TintAndShade = 0.9
        End With
    
    End If

End Sub




' DOWNLOAD WIND DAILY DATA
Sub Shoninki()
    
    
    
    '''
    '''  READ IN PARAMETERS
    '''
    
          Tok = Range("TOKEN")
      dataset = Range("DATASET")
    date_from = Range("YEAR") & "-01-01"
      date_to = Range("YEAR") & "-12-31"
          lon = Range("LON")
          lat = Range("LAT")
     capacity = Range("CAPACITY")
     aggregat = Range("AGGREGATION")
     
       Height = Range("HEIGHT")
      turbine = Range("TURBINE")

    
    
    '''
    '''  BUILD THE REQUEST URL
    '''
        
    Url = "https://www.renewables.ninja/api/data/wind?"
    
    Par = "lat=" & lat & "&lon=" & lon & "&date_from=" & date_from & "&date_to=" & date_to & _
          "&dataset=" & dataset & "&capacity=" & capacity & "&height=" & Height & _
          "&turbine=" & turbine & "&format=csv"
    
    If (aggregat <> "hour") Then Par = Par & "&mean=" & aggregat



    ' set a warning that we're updating
    Range("OUTPUT").Select
    With Range(Selection, Selection.Offset(0, 1)).Interior
        .ThemeColor = xlThemeColorAccent2
        .TintAndShade = 0.7
    End With
    
    
    
    '''
    '''  RUN API SIMULATION & DOWNLOAD DATA
    '''

    csv = Ninpiden(Url, Par, Tok)



    '''
    '''  PASTE INTO SPREADSHEET
    '''
    
    If Not (IsEmpty(csv)) Then
        
        ' spit it into the workbook
        Range("OUTPUT").Offset(1).Select
        Range(ActiveCell, ActiveCell.Offset(UBound(csv))).Value = Application.Transpose(csv)
    
        ' set a clear signal
        Range("OUTPUT").Select
        With Range(Selection, Selection.Offset(0, 1)).Interior
            .ThemeColor = xlThemeColorAccent3
            .TintAndShade = 0.9
        End With
    
    End If

End Sub





' DOWNLOADER COMPONENT
Function Ninpiden(Url As Variant, Par As Variant, Tok As Variant) As Variant



    '''
    '''  DOWNLOAD DATA
    '''

    Set httpObject = CreateObject("MSXML2.XMLHTTP")

    With httpObject
    
        .Open "GET", Url & Par, False
        .setRequestHeader "Authorization", "Token " & Tok
        .send (Par)
        

        ' wait until data has been downloaded
        Do While 1
            If .readyState = 4 Then Exit Do
            DoEvents
        Loop
              
        ' check if we were successful
        If .Status <> 200 Then
            MsgBox ("Something went wrong, you got HTTP Status " & .Status)
            Exit Function
        End If
        
        ' return the resulting code
        csv = .responseText
    
    End With


    ' split the csv into rows
    Ninpiden = Split(csv, Chr(10))


End Function





'
'
' BSD 3-Clause License
' Copyright (c) 2018, Iain Staffell
' All rights reserved.
'
'
' Redistribution and use in source and binary forms, with or without
' modification, are permitted provided that the following conditions are met:
'
' * Redistributions of source code must retain the above copyright notice, this
'   list of conditions and the following disclaimer.
'
' * Redistributions in binary form must reproduce the above copyright notice,
'   this list of conditions and the following disclaimer in the documentation
'   and/or other materials provided with the distribution.
'
' * Neither the name of the copyright holder nor the names of its
'   contributors may be used to endorse or promote products derived from
'   this software without specific prior written permission.
'
' THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
' IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
' DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
' FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
' DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
' SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
' CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
' OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
' OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
'
'
