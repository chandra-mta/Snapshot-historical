FUNCTION S2AXIS_LABELS, axis, index, value
; label axis with doy
cal = string(cxtime(value, 'sec', 'cal'))
return, cal
end

FUNCTION NO_AXIS_LABELS, axis, index, value
; suppress labelling axis
return, string(" ")
end

PRO PLOT_MOM

tmpout="momentum.tmp" ; keep the plotted values here
tlfiles=findfile('./chandraPCAD*tl')
time_lim=6L*3600 ; only plot the last time_lim seconds
                ; 5 hours allows the current (last) comm

rdfloat,tmpout,time,mom1,mom2,mom3

for i=0,n_elements(tlfiles)-1 do begin
  command="awk '{print $1"+'" "$14'+'" "$15'+'" "$16}'+"' "+ $
           tlfiles(i)+" > xm.tmp"
  spawn, command
  rdfloat,"xm.tmp",ttime,tmom1,tmom2,tmom3,skipline=3
  time=[ time, ttime]
  mom1=[mom1,tmom1]
  mom2=[mom2,tmom2]
  mom3=[mom3,tmom3]
endfor

b=sort(time)
time=time(b)
mom1=mom1(b)
mom2=mom2(b)
mom3=mom3(b)

b=where(max(time)-time lt time_lim) ; only keep the last time_lim seconds
time=time(b)
mom1=mom1(b)
mom2=mom2(b)
mom3=mom3(b)

xmin=min(time)-100
xrange=max(time)-min(time)
;xmax=max([max(time),min(time)+3600])
xmax=min(time)+(fix(xrange/3600)+1)*3600 ; assume pass is integer hours long
set_plot,'Z'
xwidth=580
yheight=580
device, set_resolution = [xwidth, yheight]

loadct,39
white=255
green=150
yellow=190
red=230

!p.multi=[0,1,3,0,0]
plot,time,mom1,psym=2,ytitle="Roll Mom. (ft*lb*sec)", $
     charsize=1.5, symsize=0.2, $
     xrange=[xmin,xmax],yrange=[min(mom1)-0.1,max(mom1)+0.1],xstyle=1, $
     ymargin=[0,3],xtitle="", xmargin=[12,0], $
     xticks=4,xtickformat='no_axis_labels',color=255,background=0
plot,time,mom2,psym=2,ytitle="Pitch Mom. (ft*lb*sec)", $
     charsize=1.5, symsize=0.2, $
     xrange=[xmin,xmax],yrange=[min(mom2)-0.1,max(mom2)+0.1],xstyle=1, $
     ymargin=[2,1],xtitle="", xmargin=[12,0], $
     xticks=4,xtickformat='no_axis_labels',color=255,background=0
plot,time,mom3,psym=2,ytitle="Yaw Mom. (ft*lb*sec)", $
     charsize=1.5, symsize=0.2, $
     xrange=[xmin,xmax],yrange=[min(mom3)-0.1,max(mom3)+0.1],xstyle=1, $
     ymargin=[4,-1],xtitle="time (UT)", xmargin=[12,0], $
     xticks=4,xtickformat='s2axis_labels',color=255,background=0
xyouts,1,0,"last update: "+systime(),align=1,color=white,/normal
write_gif,'/data/mta4/www/DAILY/mta_rt/mom_rtplot.gif',tvrd()

openw,ounit,'tmpmom.tmp',/get_lun
for i=0L,n_elements(time)-1 do begin
  printf,ounit,time(i),mom1(i),mom2(i), mom3(i), $
         format='(F11.1,3(" ",F9.3))'
endfor
free_lun,ounit
spawn,"mv tmpmom.tmp "+tmpout ; just in case there is any conflict, don't
                              ; try to read and write from the same file
end
