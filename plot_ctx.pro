FUNCTION S2AXIS_LABELS, axis, index, value
; label axis with doy
cal = string(cxtime(value, 'sec', 'cal'))
return, cal
end

FUNCTION NO_AXIS_LABELS, axis, index, value
; suppress labelling axis
return, string(" ")
end

PRO PLOT_CTX

tmpout="ctx.tmp" ; keep the plotted values here
tlfiles=findfile('./chandraCCDM*tl')
time_lim=6L*3600 ; only plot the last time_lim seconds
                ; 5 hours allows the current (last) comm

rdfloat,tmpout,time,ctx1,ctx2,ctx3,ctx4

for i=0,n_elements(tlfiles)-1 do begin
  command="awk '{print $1"+'" "$17'+'" "$18'+'" "$19'+'" "$20}'+"' "+ $
           tlfiles(i)+" > xt.tmp"
  spawn, command
  rdfloat,"xt.tmp",ttime,tctx1,tctx2,tctx3,tctx4,skipline=3
  time=[ time, ttime]
  ctx1=[ctx1,tctx1]
  ctx2=[ctx2,tctx2]
  ctx3=[ctx3,tctx3]
  ctx4=[ctx4,tctx4]
endfor

b=sort(time)
time=time(b)
ctx1=ctx1(b)
ctx2=ctx2(b)
ctx3=ctx3(b)
ctx4=ctx4(b)

b=where(max(time)-time lt time_lim) ; only keep the last time_lim seconds
time=time(b)
ctx1=ctx1(b)
ctx2=ctx2(b)
ctx3=ctx3(b)
ctx4=ctx4(b)

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

!p.multi=[0,1,2,0,0]
a_avg=moment(ctx1)
b_avg=moment(ctx2)
if (a_avg(0) gt b_avg(0)) then begin
  plot_pwr=ctx1
  plot_v=ctx3
  ctx_name='A'
endif else begin
  plot_pwr=ctx2
  plot_v=ctx4
  ctx_name='B'
endelse

plot,time,plot_pwr,psym=2,ytitle="Power (DBM)", $
     charsize=0.7, symsize=0.2, $
     xrange=[xmin,xmax],yrange=[min(plot_pwr)-0.1,max(plot_pwr)+0.1],xstyle=1, $
     ymargin=[0,3],xtitle="", xmargin=[12,0], $
     xticks=4,xtickformat='no_axis_labels',color=255,background=0
plot,time,plot_v,psym=2,ytitle="Volts", $
     charsize=0.7, symsize=0.2, $
     xrange=[xmin,xmax],yrange=[min(plot_v)-0.1,max(plot_v)+0.1],xstyle=1, $
     ymargin=[4,1],xtitle="time (UT)", xmargin=[12,0], $
     xticks=4,xtickformat='s2axis_labels',color=255,background=0
xyouts,1,0,"last update: "+systime(),align=1,color=white,/normal
write_gif,'/data/mta4/www/DAILY/mta_rt/ctx_rtplot.gif',tvrd()

openw,ounit,'tmpctx.tmp',/get_lun
for i=0L,n_elements(time)-1 do begin
  printf,ounit,time(i),ctx1(i),ctx2(i), ctx3(i), ctx4(i), $
         format='(F11.1,4(" ",F7.3))'
endfor
free_lun,ounit
spawn,"mv tmpctx.tmp "+tmpout ; just in case there is any conflict, don't
                              ; try to read and write from the same file
end
