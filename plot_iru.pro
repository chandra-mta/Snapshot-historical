FUNCTION S2AXIS_LABELS, axis, index, value
; label axis with doy
cal = string(cxtime(value, 'sec', 'cal'))
return, cal
end

FUNCTION NO_AXIS_LABELS, axis, index, value
; suppress labelling axis
return, string(" ")
end

PRO PLOT_IRU

tmpout="iru_currents.tmp" ; keep the plotted values here
tlfiles=findfile('./chandraIRU*tl')
time_lim=6L*3600 ; only plot the last time_lim seconds
                ; 5 hours allows the current (last) comm

rdfloat,tmpout,time,iru1g1i,iru1g2i,iru2g1i,iru2g2i,irubias1,irubias2,irubias3

for i=0,n_elements(tlfiles)-1 do begin
  rdfloat,tlfiles(i),ttime,tiru1g1i,tiru1g2i,tiru2g1i,tiru2g2i, $
                     tirubias1,tirubias2,tirubias3,skipline=3
  time=[ time, ttime]
  iru1g1i=[ iru1g1i, tiru1g1i]
  iru1g2i=[ iru1g2i, tiru1g2i]
  iru2g1i=[ iru2g1i, tiru2g1i]
  iru2g2i=[ iru2g2i, tiru2g2i]
  irubias1=[ irubias1, tirubias1*3600*360/2/3.14159] ; convert radps to deg/hr
  irubias2=[ irubias2, tirubias2*3600*360/2/3.14159] ; convert radps to deg/hr
  irubias3=[ irubias3, tirubias3*3600*360/2/3.14159] ; convert radps to deg/hr
endfor

b=sort(time)
time=time(b)
iru1g1i=iru1g1i(b)
iru1g2i=iru1g2i(b)
iru2g1i=iru2g1i(b)
iru2g2i=iru2g2i(b)
irubias1=irubias1(b)
irubias2=irubias2(b)
irubias3=irubias3(b)

b=where(max(time)-time lt time_lim) ; only keep the last time_lim seconds
time=time(b)
iru1g1i=iru1g1i(b)
iru1g2i=iru1g2i(b)
iru2g1i=iru2g1i(b)
iru2g2i=iru2g2i(b)
irubias1=irubias1(b)
irubias2=irubias2(b)
irubias3=irubias3(b)

xmin=min(time)-100
xrange=max(time)-min(time)
;xmax=max([max(time),min(time)+3600])
xmax=min(time)+(fix(xrange/3600)+1)*3600 ; assume pass is integer hours long
!p.multi=[0,1,4,0,0]
set_plot,'Z'
xwidth=580
yheight=580
device, set_resolution = [xwidth, yheight]

loadct,39
white=255
green=150
yellow=190
red=230
plot,time,iru1g1i,psym=2,ytitle="AIRU1G1I (mA)",charsize=1.5, symsize=0.2, $
     xrange=[xmin,xmax],yrange=[min(iru1g1i)-1,max(iru1g1i)+1],xstyle=1, $
     xticks=4,xtickformat='no_axis_labels',ymargin=[0,3],/nodata
a=where(iru1g1i ge 200,num)
if (num gt 0) then oplot,time(a),iru1g1i(a),psym=2,symsize=0.2,color=red
a=where(iru1g1i lt 200 and iru1g1i ge 150,num)
if (num gt 0) then oplot,time(a),iru1g1i(a),psym=2,symsize=0.2,color=yellow
a=where(iru1g1i lt 150,num)
if (num gt 0) then oplot,time(a),iru1g1i(a),psym=2,symsize=0.2,color=green

plot,time,iru1g2i,psym=2,ytitle="AIRU1G2I (mA)",charsize=1.5, symsize=0.2, $
     xrange=[xmin,xmax],yrange=[min(iru1g2i)-1,max(iru1g2i)+1],xstyle=1, $
     xticks=4,xtickformat='no_axis_labels',ymargin=[2,1],/nodata
a=where(iru1g2i ge 200,num)
if (num gt 0) then oplot,time(a),iru1g2i(a),psym=2,symsize=0.2,color=red
a=where(iru1g2i lt 200 and iru1g2i ge 150,num)
if (num gt 0) then oplot,time(a),iru1g2i(a),psym=2,symsize=0.2,color=yellow
a=where(iru1g2i lt 150,num)
if (num gt 0) then oplot,time(a),iru1g2i(a),psym=2,symsize=0.2,color=green

plot,time,iru2g1i,psym=2,ytitle="AIRU2G1I (mA)",charsize=1.5, symsize=0.2, $
     xrange=[xmin,xmax],yrange=[min(iru2g1i)-1,max(iru2g1i)+1],xstyle=1, $
     xticks=4,xtickformat='no_axis_labels',ymargin=[4,-1],/nodata
a=where(iru2g1i ge 650,num)
if (num gt 0) then oplot,time(a),iru2g1i(a),psym=2,symsize=0.2,color=red
a=where(iru2g1i lt 650 and iru2g1i ge 120,num)
if (num gt 0) then oplot,time(a),iru2g1i(a),psym=2,symsize=0.2,color=yellow
a=where(iru2g1i lt 120,num)
if (num gt 0) then oplot,time(a),iru2g1i(a),psym=2,symsize=0.2,color=green

plot,time,iru2g2i,psym=2,ytitle="AIRU2G2I (mA)",charsize=1.5, symsize=0.2, $
     xrange=[xmin,xmax],yrange=[min(iru2g2i)-1,max(iru2g2i)+1],xstyle=1, $
     ymargin=[6,-3],xtitle="time (UT)", $
     xticks=4,xtickformat='s2axis_labels',/nodata
a=where(iru2g2i ge 650,num)
if (num gt 0) then oplot,time(a),iru2g2i(a),psym=2,symsize=0.2,color=red
a=where(iru2g2i lt 650 and iru2g2i ge 120,num)
if (num gt 0) then oplot,time(a),iru2g2i(a),psym=2,symsize=0.2,color=yellow
a=where(iru2g2i lt 120,num)
if (num gt 0) then oplot,time(a),iru2g2i(a),psym=2,symsize=0.2,color=green

xyouts,1,0,"last update: "+systime(),align=1,color=white,/normal
;xyouts,0.5,0.98,"start time: "+cxtime(min(time),'sec','cal'), $
;       align=0.5,color=white,/normal
write_gif,'/data/mta4/www/DAILY/mta_rt/irui_rtplot.gif',tvrd()

!p.multi=[0,1,3,0,0]
plot,time,irubias1,psym=2,ytitle="Roll Bias (deg/hr)", $
     charsize=1.5, symsize=0.2, $
     xrange=[xmin,xmax],yrange=[min(irubias1)-0.001,max(irubias1)+0.001],xstyle=1, $
     ymargin=[0,3],xtitle="", xmargin=[12,0], $
     xticks=4,xtickformat='no_axis_labels',color=255,background=0
plot,time,irubias2,psym=2,ytitle="Pitch Bias (deg/hr)", $
     charsize=1.5, symsize=0.2, $
     xrange=[xmin,xmax],yrange=[min(irubias2)-0.001,max(irubias2)+0.001],xstyle=1, $
     ymargin=[2,1],xtitle="", xmargin=[12,0], $
     xticks=4,xtickformat='no_axis_labels',color=255,background=0
plot,time,irubias3,psym=2,ytitle="Yaw Bias (deg/hr)", $
     charsize=1.5, symsize=0.2, $
     xrange=[xmin,xmax],yrange=[min(irubias3)-0.001,max(irubias3)+0.001],xstyle=1, $
     ymargin=[4,-1],xtitle="time (UT)", xmargin=[12,0], $
     xticks=4,xtickformat='s2axis_labels',color=255,background=0
xyouts,1,0,"last update: "+systime(),align=1,color=white,/normal
write_gif,'/data/mta4/www/DAILY/mta_rt/irui_bias_rtplot.gif',tvrd()

openw,ounit,'tmpiru.tmp',/get_lun
for i=0L,n_elements(time)-1 do begin
  printf,ounit,time(i),iru1g1i(i),iru1g2i(i), iru2g1i(i), iru2g2i(i), $
                       irubias1(i),irubias2(i),irubias3(i), $
         format='(F11.1,4(" ",F6.2),3(" ",E12.5))'
endfor
free_lun,ounit
spawn,"mv tmpiru.tmp "+tmpout ; just in case there is any conflict, don't
                              ; try to read and write from the same file
end
