; FUNCTION CXTIME, input, from_form, to_form
; convert time from from_form to to_form
;  valid forms are: 'cal' - calendar date
;                            as input has FITS form yyyy-mm-ddThh:mm:ss
;                            as output has form yyyy-MonDD-hh:mm
;                   'sec' - seconds since 1998:001:00:00:00
;                   'met' - mission elapsed time (days since 1999:204:04:31 UT)
;                   'doy' - day of year 
;                            as input has form yyyy:doy:hh:mm:ss
;                            as output has form doy
;  if forms are not specified, 'sec' to 'met' is assumed
;      (allows easy replacement of old sdom function)
;
;  EXAMPLES:
;     print, cxtime('2001-12-05T00:00:00', 'cal','met')
;     ;       865.81181
;     print, cxtime('2001-12-05T00:00:00', 'cal','sec')
;     ;   1.2389760e+08
;     print, cxtime(1.2389760e+08, 'sec','cal')
;     ;    2001-Dec04-23:59
;
;     ;  Yes, it will do arrays:
;     met_dates=[860.1,861.1,862.1,862.6]
;     print, cxtime(met_dates, 'met', 'cal')
;     ;    2001-Nov29-06:54     2001-Nov30-06:54     2001-Dec01-06:54     
;          2001-Dec01-18:54
;     print, cxtime(120000000, 'sec', 'met')
;     ;    820.701
;     print, cxtime(120000000)
;     ;    820.701
;
; BDS 03. DEC 2001
; BDS 17. JAN 2002 -added doy 
; BDS 28. MAR 2002 -added doy as input
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FUNCTION CAL2SEC_DO, input
; same as ymd2sec, 30.Nov2001 BDS
; given data, return seconds since 1998:001:00:00:00
; input format should be yyyy-mm-ddThh:mm:ss 
;               ex.      2000-12-31T01:00:00
; written to translate dates from cti observations
; Brad Spitzbart
; Jan 31 2001
ttmp = strarr(2)
ttmp = strsplit(input, 'T', /extract)
tdate = strsplit(ttmp(0), '-', /extract)
ttime = strsplit(ttmp(1), ':', /extract)
; convert date to seconds since 1998-01-01 00:00:00
year = (float(tdate(0))-1998)*31536000
case (fix(tdate(1))) of
  01: month = 0   * 86400
  02: month = 31  * 86400
  03: month = 59  * 86400
  04: month = 90  * 86400
  05: month = 120 * 86400
  06: month = 151 * 86400
  07: month = 181 * 86400
  08: month = 212 * 86400
  09: month = 243 * 86400
  10: month = 273 * 86400
  11: month = 304 * 86400
  12: month = 334 * 86400
endcase

day = (float(tdate(2))-1)*86400
  
ttimes = double(year + month + day + $
         3600*float(ttime(0)) + 60*float(ttime(1)) + float(ttime(2)))

; add leap years
leap = 68169600  ; March 1, 2000 - first extra day needs to be added
while (ttimes ge leap) do begin
  ttimes = ttimes + 86400
  leap = leap + (31536000 * 4)
endwhile

return, ttimes
end

FUNCTION CAL2SEC, input
; wrapper for cal2sec_do
;  determine if you have single value or array
;  (might not work quite right for 1 element array)
num = n_elements(input)
if (num le 1) then begin
  return, cal2sec_do(input)
endif else begin ; process whole array
  out = fltarr(num)
  for i = 0L, num-1 do begin
    out(i) = cal2sec_do(input(i))
  endfor
  return, out
endelse
end

FUNCTION MET2CAL_DO, met 
; convert mission elapsed time (days) to calendar date (UT)
; input is float
; output is string
; see s2met.pro

secs_per_yr = 31536000.0
secs_per_day = 86400.0

; convert to seconds since 1998:00:00:00.00
sec = double(86400 * (float(met) + 204.0 + 365.0 + 4.0/24.0 + 31.0/1440.0))
 
; convert to calendar date
year = 1998
leap = 2000
done = 0
while (done eq 0) do begin
  if (year eq leap) then begin
    if (sec gt secs_per_yr + secs_per_day) then begin
      sec = sec - secs_per_yr - secs_per_day
      leap = leap + 4
      year = year + 1
    endif else done = 1
  endif else begin
    if (sec gt secs_per_yr) then begin
      sec = sec - secs_per_yr
      year = year + 1
    endif else done = 1
  endelse
endwhile
    
;while (sec gt secs_per_yr) do begin
;  year = year + 1
;  sec = sec - secs_per_yr
;  if (year eq leap) then begin
;    sec = sec - secs_per_day
;    leap = leap + 4
;  endif
;endwhile

mnth_lst = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', $
            'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
mnth_len = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
; add leap day to feb if neccesary
leap = 2000
while (year ge leap) do begin
  if (year eq leap) then mnth_len(1) = 29
  leap = leap + 4
endwhile

mnth_cum = intarr(13)
for i = 1, 12 do begin
  for j = 0, i-1 do begin
    mnth_cum(i) = mnth_cum(i-1) + mnth_len(j)
  endfor
endfor

i = 0 ; month indexer
days = sec/secs_per_day

; something weird happens at end of year
if (days lt 1.0) then begin
  days = days + mnth_cum(12)
  year = year - 1
endif

while (days ge mnth_cum(i)+1.0) do begin
  i = i + 1
endwhile

month = strtrim(string(mnth_lst(i-1)),2)
day = days - mnth_cum(i-1)
tmp = strarr(2)
tmp = strsplit(string(day), '.', /extract)
date = strtrim(string(fix(tmp(0))), 2)
if (strlen(date) lt 2) then date = '0'+date
timet = '0.'+tmp(1)
hourt = float(timet) * 24
tmp = strarr(2)
tmp = strsplit(string(hourt), '.', /extract)
hour = strtrim(string(tmp(0)),2)
if (strlen(hour) lt 2) then hour = '0'+hour
timet = '0.'+tmp(1)
min = strtrim(string(fix(float(timet) * 60)),2)
if (strlen(min) lt 2) then min = '0'+min

cal = strcompress(string(year)+'-'+month+date+$
       '-'+hour+':'+min, /remove_all)
return, cal
end

FUNCTION MET2CAL, input
; wrapper for met2cal_do
;  determine if you have single value or array
;  (might not work quite right for 1 element array)
num = n_elements(input)
if (num le 1) then begin
  return, met2cal_do(input)
endif else begin ; process whole array
  out = strarr(num)
  for i = 0L, num-1 do begin
    out(i) = met2cal_do(input(i))
  endfor
  return, out
endelse
end

FUNCTION S2MET, secs 
; convert seconds since 1998:00:00:00.00 to mission elapsed time 
;    (days since 1999:204:04:31 GMT, 07/23/99 00:31 EDT Launch)
tdom = (secs / 86400.0) - 203.0 - 365.0 - 4.0/24.0 - 31.0/1440.0
return, tdom
end

FUNCTION MET2S, met
; convert mission elapsed time 
;    (days since 1999:204:04:31 GMT, 07/23/99 00:31 EDT Launch)
; to seconds since 1998:00:00:00.00
tsec = met + 203.0 + 365.0 + 4.0/24.0 + 31.0/1440.0
return, tsec * 86400
end

FUNCTION S2DOY_DO, secs, YR=yr
; convert seconds since 1998:001:00:00.00 to DOY
; optionally return year in yr (not implemented yet)
sperdy = 86400.0
speryr = [replicate(sperdy*365.0,3),sperdy*366.0] ; automatically account 
lyear = 1                                         ; for leap years
tmp = secs
yr = 1998
while (tmp ge speryr(lyear)) do begin
  tmp = tmp - speryr(lyear)
  lyear = (lyear + 1) mod 4
  yr = yr + 1
endwhile ; secs gt speryr
return, (1.0*tmp/sperdy) + 1.0
end

FUNCTION S2DOY, input, YR=yr
; wrapper for s2doy_do
;  determine if you have single value or array
;  (might not work quite right for 1 element array)
num = n_elements(input)
if (num le 1) then begin
  return, s2doy_do(input)
endif else begin ; process whole array
  out = strarr(num)
  for i = 0L, num-1 do begin
    out(i) = s2doy_do(input(i))
  endfor
  return, out
endelse
end

FUNCTION DOY2S_DO, indoy
; convert yyyy:doy:hh:mm:ss to seconds since 1998:001:00:00.00
sperdy = 86400.0
speryr = [replicate(sperdy*365.0,3),sperdy*366.0] ; automatically account 
lyear = 1                                         ; for leap years
yr = 1998

input=fltarr(5)
input = strsplit(indoy,":",/extract)
year=input(0)
doy=input(1)
hh=input(2)
mm=input(3)
ss=input(4)

secs=0.0
while (year gt yr) do begin
  secs = secs + speryr(lyear)
  lyear = (lyear + 1) mod 4
  yr = yr + 1
endwhile ; year gt yr
secs=secs + double((doy-1)*sperdy + hh*3600.0 + mm*60.0 + ss)
return, secs
end

FUNCTION DOY2S, input
; wrapper for doy2s_do
;  determine if you have single value or array
;  (might not work quite right for 1 element array)
num = n_elements(input)
if (num le 1) then begin
  return, doy2s_do(input)
endif else begin ; process whole array
  out = strarr(num)
  for i = 0L, num-1 do begin
    out(i) = doy2s_do(input(i))
  endfor
  return, out
endelse
end

FUNCTION CXTIME, input, from_form, to_form

; default conversion
if (n_params() lt 3) then to_form = 'met'
if (n_params() lt 2) then from_form = 'sec'
if (n_params() lt 1) then return, -1

from_form = strupcase(strcompress(from_form, /remove_all))
to_form = strupcase(strcompress(to_form, /remove_all))
if (from_form eq to_form) then return, input
if (from_form eq 'CAL') then begin
  if (to_form eq 'SEC') then return, cal2sec(input)
  if (to_form eq 'MET') then return, s2met(cal2sec(input))
  if (to_form eq 'DOY') then return, s2doy(cal2sec(input))
  ; if you haven't returned already, something is wrong
  print, "Invalid time conversion to "+to_form
  return, input
endif
if (from_form eq 'MET') then begin
  if (to_form eq 'CAL') then return, met2cal(input)
  if (to_form eq 'SEC') then return, met2s(input)
  if (to_form eq 'DOY') then return, s2doy(met2s(input))
  ; if you haven't returned already, something is wrong
  print, "Invalid time conversion to "+to_form
  return, input
endif
if (from_form eq 'SEC') then begin
  if (to_form eq 'MET') then return, s2met(input)
  if (to_form eq 'CAL') then return, met2cal(s2met(input))
  if (to_form eq 'DOY') then return, s2doy(input)
  ; if you haven't returned already, something is wrong
  print, "Invalid time conversion to "+to_form
  return, input
endif
if (from_form eq 'DOY') then begin
  if (to_form eq 'MET') then return, s2met(doy2s(input))
  if (to_form eq 'CAL') then return, met2cal(s2met(doy2s(input)))
  if (to_form eq 'SEC') then return, doy2s(input)
  ; if you haven't returned already, something is wrong
  print, "Invalid time conversion to "+to_form
  return, input
endif
; if you haven't returned already, something is wrong
print, "Invalid time conversion from "+from_form
return, input
end
