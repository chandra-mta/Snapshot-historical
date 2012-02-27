# this module writes out the chandra snapshot

sub write_txt {
  my %h = @_;

# construct the snapshot page
my $s = sprintf "UTC %s f_ACE %.2e F_CRM %.2e Kp %.1f R km%7s%s\n",${$h{UTC}}[1],${$h{FLUXACE}}[1],${$h{CRM}}[1],${$h{KP}}[1],${$h{EPHEM_ALT}}[1],${$h{EPHEM_LEG}}[1];

$s .= sprintf "OBT %s  CTUVCDU %8d  OBC s/w %s  %s_%-4s   CPEstat %s\n",
    ${$h{OBT}}[1],${$h{CCSDSVCD}}[1],${$h{CONLOFP}}[1],${$h{CCSDSTMF}}[1],${$h{COTLRDSF}}[1],${$h{AOCPESTL}}[1];

$s .= sprintf "OBT %17.2f  ONLVCDU %8d  OBC Errs%4d\n",${$h{OBT}}[0],${$h{OFLVCDCT}}[1],${$h{COERRCN}}[1];

$s .= sprintf "                                                     OBSID  %5d  EPState %4s\n",
    ${$h{COBSRQID}}[1], ${$h{EPSTATE}}[1];

$s .= sprintf "SIM TTpos %7d  HETG Angle%6.2f  PCADMODE %s   RA   %7.3f  Bus V %6.2f\n",
    ${$h{"3TSCPOS"}}[1],${$h{"4HPOSARO"}}[1],${$h{AOPCADMD}}[1],${$h{RA}}[1],${$h{ELBV}}[1];

$s .= sprintf "SIM FApos %7d  LETG Angle%6.2f  PCONTROL %s   Dec  %7.3f  Bus I %6.2f\n",
    ${$h{"3FAPOS"}}[1],${$h{"4LPOSBRO"}}[1],${$h{AOCONLAW}}[1],${$h{DEC}}[1],${$h{ELBI_LOW}}[1];

$s .= sprintf "                                     AOFSTAR  %s   Roll %7.3f\n",
    ${$h{AOFSTAR}}[1],${$h{ROLL}}[1];

$s .= sprintf "ACA Object %s    Dither  %s                                HRC-I HV %3s\n",
    ${h{ACAOBJ}}[1],${$h{AODITHEN}}[1],${$h{"2IMONST"}}[1];

$s .= sprintf "ACA ImFunc %s    Dith Yang %6.2f    Yaw Rate   %7.2f      HRC-S HV %3s\n",
    ${$h{ACAFCT}}[1],${$h{AODITHR3}}[1],${$h{AORATE3}}[1],${$h{"2SPONST"}}[1];

$s .= sprintf "ACA CCD Temp %6.1f    Dith Zang %6.2f    Pitch Rate %7.2f      SHLD HV %4.1f\n",
${$h{AACCCDPT}}[1],${$h{AODITHR2}}[1],${$h{AORATE2}}[1],${$h{"2S2HVST"}}[1];

$s .= sprintf "ACA Int Time %6.3f                        Roll Rate  %7.2f      EVT RT  %4d\n",
    ${$h{AOACINTT}}[1],${$h{AORATE1}}[1],${$h{"2DETART"}}[1];

$s .= sprintf "AOACSTAT       %4s    FSS SunBeta %4s                            SHLD RT %4d\n",
    ${$h{AOACSTAT}}[1],${$h{AOBETSUN}}[1],${$h{"2SHLDART"}}[1];

$s .= sprintf "                       FSS Alfa  %6.2f    Batt 1 SOC %7.2f%%\n",
    ${$h{AOALPANG}}[1],${$h{SOCB1}}[1];

$s .= sprintf "Avg HRMA Temp%6.2f    FSS Beta  %6.2f    Batt 2 SOC %7.2f%%  ACIS Stat7-0 %s\n",
    ${$h{"4OAVHRMT"}}[1],${$h{AOBETANG}}[1],${$h{SOCB2}}[1], ${$h{ACISTAT}}[1];

$s .= sprintf "Avg OBA Temp %6.2f    SA Resolv %6.2f    Batt 3 SOC %7.2f%%  Cold Rad %6.1f\n",
    ${$h{"4OAVOBAT"}}[1],${$h{AOSARES1}}[1], ${$h{SOCB3}}[1], ${$h{"1CRAT"}}[1];

$s .= sprintf "OBA Tavg Fault %s    SA Sun Pres %4s                         Warm Rad %6.1f\n",
    ${$h{"4OBAVTMF"}}[1], ${$h{AOSAILLM}}[1], ${$h{"1WRAT"}}[1];

$s .= sprintf "OBA Trng Fault %s                        +Y SA Amps %7.2f   RadMon     %4s\n",
    ${$h{"4OBTOORF"}}[1], ${$h{ESAPYI}}[1], ${$h{CORADMEN}}[1];

$s .= sprintf "HRMA power  %7.2f    SCS 128  %4s       -Y SA Amps %7.2f   EPHIN Geom %4s\n",
    ${$h{OHRMAPWR}}[1], ${$h{COSCS128S}}[1], ${$h{ESAMYI}}[1], ${$h{GEOM}}[1];

$s .= sprintf "OBA power   %7.2f    SCS 129  %4s       +Y SA Temp %7.2f   E150%11.1f\n",
    ${$h{OOBAPWR}}[1], ${$h{COSCS129S}}[1], ${$h{TSAPYT}}[1], ${$h{E150}}[1];

$s .= sprintf "                       SCS 130  %4s       -Y SA Temp %7.2f   E300%11.1f\n",
    ${$h{COSCS130S}}[1], ${$h{TSAMYT}}[1], ${$h{E300}}[1];

#$s .= sprintf "Roll Mom.  %8.3f                                             E1300%10.1f\n",
    #${$h{AOSYMOM1}}[1], $eph{E1300};
$s .= sprintf "Roll Mom.  %8.3f    SCS 131  %4s                            E1300%10.1f\n",
    ${$h{AOSYMOM1}}[1], ${$h{COSCS131S}}[1], ${$h{E1300}}[1];

$s .= sprintf "Pitch Mom. %8.3f    SCS 132  %4s       EPH A-Leak%8.4f   UpLCmdAcc%6d\n",
    ${$h{AOSYMOM2}}[1], ${$h{COSCS132S}}[1], ${$h{ALEAK}}[1], ${$h{CULACC}}[1];

$s .= sprintf "Yaw Mom.   %8.3f    SCS 133  %4s       EPH B-Leak%8.4f   Cmd Rej A%6d\n",
    ${$h{AOSYMOM3}}[1], ${$h{COSCS133S}}[1], ${$h{"5EHSE500"}}[1], ${$h{CMRJCNTA}}[1];

$s .= sprintf "PMTANKP    %8.3f    SCS 107  %4s       EPH temp %9.2f\n", ${$h{PMTANKP}}[1],${$h{COSCS107S}}[1],${$h{TEPHIN}}[1];

#$s .= sprintf "Gyro 2 Curr 1 %6.2f                  ", ${$h{AIRU2G1I}}[1];
##$s .= sprintf "\nGyro 1 Curr 1 %6.2f  Roll Bias   %7.4f  EPH 27I %9.2f", ${$h{AIRU1G1I}}[1], ${$h{AOGBIAS1}}[1]*206264.98, ${$h{"5HSE202"}}[1];
#$s .= sprintf "%25s M Unload %6s\n", " ",${$h{AOUNLOAD}}[1];
#$s .= sprintf "Gyro 2 Curr 2 %6.2f  Roll Bias  %7.4f", ${$h{AIRU2G2I}}[1], ${$h{AOGBIAS1}}[1]*206264.98;
#if (${$h{CTXAPWR}}[1] > 15) {
  #$s .= sprintf "   CTX A PWR   %6.2f", ${$h{CTXAPWR}}[1];
#} else {
  #$s .= sprintf "   CTX B PWR   %6.2f", ${$h{CTXBPWR}}[1];
#}
#$s .= sprintf "   TSC Move %6s\n", ${$h{"3TSCMOVE"}}[1];
#$s .= sprintf "Prop. line 03 %6.2f  Pitch Bias %7.4f", ${$h{PLINE03T}}[1], ${$h{AOGBIAS2}}[1]*206264.98;
#if (${$h{CTXAV}}[1] > 1) {
  #$s .= sprintf "   CTX A Volts %6.2f", ${$h{CTXAV}}[1];
#} else {
  #$s .= sprintf "   CTX B Volts %6.2f", ${$h{CTXBV}}[1];
#}
#$s .= sprintf "   FA Move  %6s\n", ${$h{"3FAMOVE"}}[1];
#$s .= sprintf "Prop. line 04 %6.2f  Yaw Bias   %7.4f", ${$h{PLINE04T}}[1], ${$h{AOGBIAS3}}[1]*206264.98;
#$s .= sprintf "%23s OTG Move %6s\n", " ",${$h{"4OOTGMEF"}}[1];

$s .= sprintf "Gyro 2 Curr 1 %6.2f   ",
               ${$h{AIRU2G1I}}[1];
if ((${$h{"5EHSE106"}}[1]) % 2 == 1) {
  $s .= sprintf "%18s  EPH 27V  %9.2f",
                 " ", ${$h{"5HSE202"}}[1];
} else {
  $s .= sprintf "%18s  EPH 27I  %9.2f",
                 " ",${$h{"5HSE202"}}[1]*20.1/31.05;
} # if ((${$h{"5EHSE106"}}[3]+1) % 2 == 0) {
$s .= sprintf "%3sM Unload %6s\n",
               " ", ${$h{AOUNLOAD}}[1];
$s .= sprintf "Gyro 2 Curr 2 %6.2f   ",
               ${$h{AIRU2G2I}}[1];
$s .= sprintf "Roll Bias  %7.4f",
               ${$h{AOGBIAS1}}[1]*206264.98;
$s .= sprintf "%23sTSC Move %6s\n",
               " ", ${$h{"3TSCMOVE"}}[1];
$s .= sprintf "Prop. line 03 %6.2f   ",
               ${$h{PLINE03T}}[1];
$s .= sprintf "Pitch Bias %7.4f",
               ${$h{AOGBIAS2}}[1]*206264.98;
if (${$h{CTXAPWR}}[1] > 15) {
  $s .= sprintf "  CTX A PWR  %7.2f", ${$h{CTXAPWR}}[1];
} else {
  $s .= sprintf "  CTX B PWR  %7.2f", ${$h{CTXBPWR}}[1];
}
$s .= sprintf "   FA Move  %6s\n",
               ${$h{"3FAMOVE"}}[1];
$s .= sprintf "Prop. line 04 %6.2f",
               ${$h{PLINE04T}}[1];
$s .= sprintf "%3sYaw Bias   %7.4f",
               " ", ${$h{AOGBIAS3}}[1]*206264.98;
if (${$h{CTXAV}}[1] > 1) {
  $s .= sprintf "  CTX A Volts  %5.2f", ${$h{CTXAV}}[1];
} else {
  $s .= sprintf "  CTX B Volts  %5.2f", ${$h{CTXBV}}[1];
}
$s .= sprintf "%3sOTG Move %6s\n",
               " ",${$h{"4OOTGMEF"}}[1];

return $s;

}

sub write_htm {
  my %h = @_;

# construct the annotated snapshot page
my $s = sprintf "<font color=%s>UTC %s </font>",
              ${$h{UTC}}[3], ${$h{UTC}}[1];
$s .= sprintf "<font color=%s>f_ACE %.2e </font>",
              ${$h{FLUXACE}}[3], ${$h{FLUXACE}}[1];
#$s .= sprintf "<font color=%s>F_ACE %.2e </font>",
#              ${$h{FLUACE}}[3], ${$h{FLUACE}}[1];
$s .= sprintf "<font color=%s>F_CRM %.2e </font>",
              ${$h{CRM}}[3], ${$h{CRM}}[1];
$s .= sprintf "<font color=%s>Kp %.1f </font>",
              ${$h{KP}}[3], ${$h{KP}}[1];
$s .= sprintf "<font color=%s>R km%7s%s</font>\n",
              ${$h{EPHEM_ALT}}[3], ${$h{EPHEM_ALT}}[1],${$h{EPHEM_LEG}}[1];

$s .= sprintf "<font color=%s>OBT %s  </font>",
               ${$h{OBT}}[3], ${$h{OBT}}[1];
$s .= sprintf "<font color=%s>CTUVCDU %8d  </font>",
               ${$h{CCSDSVCD}}[3], ${$h{CCSDSVCD}}[1];
$s .= sprintf "<font color=%s>OBC s/w %s  </font>",
               ${$h{CONLOFP}}[3], ${$h{CONLOFP}}[1];
$s .= sprintf "<font color=%s>%s_%-4s   </font>",
               ${$h{CCSDSTMF}}[3],${$h{CCSDSTMF}}[1],${$h{COTLRDSF}}[1];
$s .= sprintf "<font color=%s>CPEstat %s</font>\n",
               ${$h{AOCPESTL}}[3], ${$h{AOCPESTL}}[1];

$s .= sprintf "<font color=%s>OBT %17.2f  </font>",
               ${$h{OBT}}[3], ${$h{OBT}}[0];
$s .= sprintf "<font color=%s>ONLVCDU %8d  </font>",
               ${$h{OFLVCDCT}}[3], ${$h{OFLVCDCT}}[1];
$s .= sprintf "<font color=%s>OBC Errs%4d</font>\n",
               ${$h{COERRCN}}[3], ${$h{COERRCN}}[1];

$s .= sprintf "                                                     ";
$s .= sprintf "<font color=%s>OBSID  %5d  </font>",
               ${$h{COBSRQID}}[3], ${$h{COBSRQID}}[1];
$s .= sprintf "<font color=%s>EPState %4s</font>\n",
               ${$h{EPSTATE}}[3], ${$h{EPSTATE}}[1];

$s .= sprintf "<font color=%s>SIM TTpos %7d  </font>",
               ${$h{"3TSCPOS"}}[3], ${$h{"3TSCPOS"}}[1];
$s .= sprintf "<font color=%s>HETG Angle%6.2f  </font>",
               ${$h{"4HPOSARO"}}[3], ${$h{"4HPOSARO"}}[1];
$s .= sprintf "<font color=%s>PCADMODE %s   </font>",
               ${$h{AOPCADMD}}[3], ${$h{AOPCADMD}}[1];
$s .= sprintf "<font color=%s>RA   %7.3f  </font>",
               ${$h{RA}}[3], ${$h{RA}}[1];
$s .= sprintf "<font color=%s>Bus V %6.2f</font>\n",
               ${$h{ELBV}}[3], ${$h{ELBV}}[1];

$s .= sprintf "<font color=%s>SIM FApos %7d  </font>",
               ${$h{"3FAPOS"}}[3], ${$h{"3FAPOS"}}[1];
$s .= sprintf "<font color=%s>LETG Angle%6.2f  </font>",
               ${$h{"4LPOSBRO"}}[3], ${$h{"4LPOSBRO"}}[1];
$s .= sprintf "<font color=%s>PCONTROL %s   </font>",
               ${$h{AOCONLAW}}[3], ${$h{AOCONLAW}}[1];
$s .= sprintf "<font color=%s>Dec  %7.3f  </font>",
               ${$h{DEC}}[3], ${$h{DEC}}[1];
$s .= sprintf "<font color=%s>Bus I %6.2f</font>\n",
               ${$h{ELBI_LOW}}[3], ${$h{ELBI_LOW}}[1];

$s .= sprintf "                                     ";
$s .= sprintf "<font color=%s>AOFSTAR  %s   </font>",
               ${$h{AOFSTAR}}[3], ${$h{AOFSTAR}}[1];
$s .= sprintf "<font color=%s>Roll %7.3f</font>\n",
               ${$h{ROLL}}[3], ${$h{ROLL}}[1];

$s .= sprintf "<font color=%s>ACA Object %s    </font>",
               ${h{ACAOBJ}}[3], ${h{ACAOBJ}}[1];
$s .= sprintf "<font color=%s>Dither  %s       </font>",
               ${$h{AODITHEN}}[3], ${$h{AODITHEN}}[1];
$s .= sprintf "                         ";
$s .= sprintf "<font color=%s>HRC-I HV %3s</font>\n",
               ${$h{"2IMONST"}}[3], ${$h{"2IMONST"}}[1];

# add color annotation if not tracking, highlight red for science obs,
#              yellow for non-science.
my $ImNote = ${$h{ACAFCT}}[1];
if (${$h{ACAFCT}}[2] eq 'N') {
  $ImNote =~ s/T/<font color=33CC00>T<\/font>/g;
}
$s .= sprintf "<font color=%s>ACA ImFunc %s    </font>",
               ${$h{ACAFCT}}[3], $ImNote;
$s .= sprintf "<font color=%s>Dith Yang %6.2f    </font>",
               ${$h{AODITHR3}}[3], ${$h{AODITHR3}}[1];
$s .= sprintf "<font color=%s>Yaw Rate   %7.2f      </font>",
               ${$h{AORATE3}}[3], ${$h{AORATE3}}[1];
$s .= sprintf "<font color=%s>HRC-S HV %3s</font>\n",
               ${$h{"2SPONST"}}[3], ${$h{"2SPONST"}}[1];

$s .= sprintf "<font color=%s>ACA CCD Temp %6.1f    </font>",
               ${$h{AACCCDPT}}[3], ${$h{AACCCDPT}}[1];
$s .= sprintf "<font color=%s>Dith Zang %6.2f    </font>",
               ${$h{AODITHR2}}[3], ${$h{AODITHR2}}[1];
$s .= sprintf "<font color=%s>Pitch Rate %7.2f      </font>",
               ${$h{AORATE2}}[3], ${$h{AORATE2}}[1];
$s .= sprintf "<font color=%s>SHLD HV %4.1f</font>\n",
               ${$h{"2S2HVST"}}[3], ${$h{"2S2HVST"}}[1];

$s .= sprintf "<font color=%s>ACA Int Time %6.3f                        </font>",
               ${$h{AOACINTT}}[3], ${$h{AOACINTT}}[1];
$s .= sprintf "<font color=%s>Roll Rate  %7.2f      </font>",
               ${$h{AORATE1}}[3], ${$h{AORATE1}}[1];
$s .= sprintf "<font color=%s>EVT RT  %4d</font>\n",
               ${$h{"2DETART"}}[3], ${$h{"2DETART"}}[1];

$s .= sprintf "<font color=%s>AOACSTAT       %4s    </font>",
               ${$h{AOACSTAT}}[3], ${$h{AOACSTAT}}[1];
$s .= sprintf "<font color=%s>FSS SunBeta %4s                            </font>",
               ${$h{AOBETSUN}}[3], ${$h{AOBETSUN}}[1];
$s .= sprintf "<font color=%s>SHLD RT %4d</font>\n",
               ${$h{"2SHLDART"}}[3], ${$h{"2SHLDART"}}[1];

$s .= sprintf "                       ";
$s .= sprintf "<font color=%s>FSS Alfa  %6.2f    </font>",
               ${$h{AOALPANG}}[3], ${$h{AOALPANG}}[1];
$s .= sprintf "<font color=%s>Batt 1 SOC %7.2f%%</font>\n",
               ${$h{SOCB1}}[3], ${$h{SOCB1}}[1];

$s .= sprintf "<font color=%s>Avg HRMA Temp%6.2f    </font>",
               ${$h{"4OAVHRMT"}}[3], ${$h{"4OAVHRMT"}}[1];
$s .= sprintf "<font color=%s>FSS Beta  %6.2f    </font>",
               ${$h{AOBETANG}}[3], ${$h{AOBETANG}}[1];
$s .= sprintf "<font color=%s>Batt 2 SOC %7.2f%%  </font>",
               ${$h{SOCB2}}[3], ${$h{SOCB2}}[1];
$s .= sprintf "<font color=%s>ACIS Stat7-0 %s</font>\n",
               ${$h{ACISTAT}}[3], ${$h{ACISTAT}}[1];

$s .= sprintf "<font color=%s>Avg OBA Temp %6.2f    </font>",
               ${$h{"4OAVOBAT"}}[3], ${$h{"4OAVOBAT"}}[1];
$s .= sprintf "<font color=%s>SA Resolv %6.2f    </font>",
               ${$h{AOSARES1}}[3], ${$h{AOSARES1}}[1];
$s .= sprintf "<font color=%s>Batt 3 SOC %7.2f%%  </font>",
               ${$h{SOCB3}}[3], ${$h{SOCB3}}[1];
$s .= sprintf "<font color=%s>Cold Rad %6.1f</font>\n",
               ${$h{"1CRAT"}}[3], ${$h{"1CRAT"}}[1];

$s .= sprintf "<font color=%s>OBA Tavg Fault %s    </font>",
               ${$h{"4OBAVTMF"}}[3], ${$h{"4OBAVTMF"}}[1];
$s .= sprintf "<font color=%s>SA Sun Pres %4s                         </font>",
               ${$h{AOSAILLM}}[3], ${$h{AOSAILLM}}[1];
$s .= sprintf "<font color=%s>Warm Rad %6.1f</font>\n",
               ${$h{"1WRAT"}}[3], ${$h{"1WRAT"}}[1];

$s .= sprintf "<font color=%s>OBA Trng Fault %s                        </font>",
               ${$h{"4OBTOORF"}}[3], ${$h{"4OBTOORF"}}[1];
$s .= sprintf "<font color=%s>+Y SA Amps %7.2f   </font>",
               ${$h{ESAPYI}}[3], ${$h{ESAPYI}}[1];
$s .= sprintf "<font color=%s>RadMon     %4s</font>\n",
               ${$h{CORADMEN}}[3], ${$h{CORADMEN}}[1];

$s .= sprintf "<font color=%s>HRMA power  %7.2f    </font>",
               ${$h{OHRMAPWR}}[3], ${$h{OHRMAPWR}}[1];
$s .= sprintf "<font color=%s>SCS 128  %4s       </font>",
               ${$h{COSCS128S}}[3], ${$h{COSCS128S}}[1];
$s .= sprintf "<font color=%s>-Y SA Amps %7.2f   </font>",
               ${$h{ESAMYI}}[3], ${$h{ESAMYI}}[1];
$s .= sprintf "<font color=%s>EPHIN Geom %4s</font>\n",
               ${$h{GEOM}}[3], ${$h{GEOM}}[1];
    

$s .= sprintf "<font color=%s>OBA power   %7.2f    </font>",
               ${$h{OOBAPWR}}[3], ${$h{OOBAPWR}}[1];
$s .= sprintf "<font color=%s>SCS 129  %4s       </font>",
               ${$h{COSCS129S}}[3], ${$h{COSCS129S}}[1];
$s .= sprintf "<font color=%s>+Y SA Temp %7.2f   </font>",
               ${$h{TSAPYT}}[3], ${$h{TSAPYT}}[1];
$s .= sprintf "<font color=%s>E150%11.1f</font>\n",
               ${$h{E150}}[3], ${$h{E150}}[1];

$s .= sprintf "                       ";
$s .= sprintf "<font color=%s>SCS 130  %4s       </font>",
               ${$h{COSCS130S}}[3], ${$h{COSCS130S}}[1];
$s .= sprintf "<font color=%s>-Y SA Temp %7.2f   </font>",
               ${$h{TSAMYT}}[3], ${$h{TSAMYT}}[1];
$s .= sprintf "<font color=%s>E300%11.1f</font>\n",
               ${$h{E300}}[3], ${$h{E300}}[1];

$s .= sprintf '<a href="http://cxc.harvard.edu/mta/DAILY/mta_rt/mom_plot.html" STYLE="text-decoration: none" target="blank">';
$s .= sprintf "<font color=%s>Roll Mom.  %8.3f    </font></a>",
               ${$h{AOSYMOM1}}[3], ${$h{AOSYMOM1}}[1];
$s .= sprintf "<font color=%s>SCS 131  %4s                            </font>",
               ${$h{COSCS131S}}[3], ${$h{COSCS131S}}[1];
$s .= sprintf "<font color=%s>E1300%10.1f</font>\n",
               ${$h{E1300}}[3], ${$h{E1300}}[1];

$s .= sprintf '<a href="http://cxc.harvard.edu/mta/DAILY/mta_rt/mom_plot.html" STYLE="text-decoration: none" target="blank">';
$s .= sprintf "<font color=%s>Pitch Mom. %8.3f    </font></a>",
               ${$h{AOSYMOM2}}[3], ${$h{AOSYMOM2}}[1];
$s .= sprintf "<font color=%s>SCS 132  %4s       </font>",
               ${$h{COSCS132S}}[3], ${$h{COSCS132S}}[1];
$s .= sprintf "<font color=%s>EPH A-Leak%8.4f   </font>",
               ${$h{ALEAK}}[3], ${$h{ALEAK}}[1];
$s .= sprintf "<font color=%s>UpLCmdAcc%6d   </font>\n",
               ${$h{CULACC}}[3], ${$h{CULACC}}[1];
#$s .= sprintf "<font color=%s>P4GM%11.1f</font>\n",
               ##${$h{P4GM}}[3], ${$h{P4GM}}[1];
               #"#999999", ${$h{P4GM}}[1];

$s .= sprintf '<a href="http://cxc.harvard.edu/mta/DAILY/mta_rt/mom_plot.html" STYLE="text-decoration: none" target="blank">';
$s .= sprintf "<font color=%s>Yaw Mom.   %8.3f    </font></a>",
               ${$h{AOSYMOM3}}[3], ${$h{AOSYMOM3}}[1];
$s .= sprintf "<font color=%s>SCS 133  %4s       </font>",
               ${$h{COSCS133S}}[3], ${$h{COSCS133S}}[1];
$s .= sprintf "<font color=%s>EPH B-Leak%8.4f   </font>",
               ${$h{"5EHSE500"}}[3], ${$h{"5EHSE500"}}[1];
$s .= sprintf "<font color=%s>Cmd Rej A%6d   </font>\n",
               ${$h{CMRJCNTA}}[3], ${$h{CMRJCNTA}}[1];
#$s .= sprintf "<font color=%s>P41GM%10.1f</font>\n",
               ##${$h{P41GM}}[3], ${$h{P41GM}}[1];
               #"#999999", ${$h{P41GM}}[1];

$s .= sprintf "<font color=%s>PMTANKP     %7.3f    </font></a>",
               ${$h{PMTANKP}}[3], ${$h{PMTANKP}}[1];
$s .= sprintf "<font color=%s>SCS 107  %4s       </font>",
               ${$h{COSCS107S}}[3], ${$h{COSCS107S}}[1];
$s .= sprintf "<font color=%s>EPH temp %9.2f   </font>\n",
               ${$h{"TEPHIN"}}[3], ${$h{"TEPHIN"}}[1];

#$s .= sprintf "<font color=%s>PMTANKP     %8.3f </font>%23s<font color=%s>EPH temp %9.2f</font>\n",${$h{PMTANKP}}[3],${$h{PMTANKP}}[1]," ",${$h{TEPHIN}}[3], ${$h{TEPHIN}}[1];

$s .= sprintf '<a href="http://cxc.harvard.edu/mta/DAILY/mta_rt/iru_plot.html" STYLE="text-decoration: none" target="blank">';
$s .= sprintf "<font color=%s>Gyro 2 Curr 1 %6.2f</font></a>   ", 
               ${$h{AIRU2G1I}}[3], ${$h{AIRU2G1I}}[1];
if ((${$h{"5EHSE106"}}[1]) % 2 == 1) {
  $s .= sprintf "%18s<font color=%s>  EPH 27V  %9.2f</font></a>", 
                 " ",${$h{"5HSE202"}}[3], ${$h{"5HSE202"}}[1];
} else {
  $s .= sprintf "%18s<font color=%s>  EPH 27I  %9.2f</font></a>", 
                 " ",${$h{"5HSE202"}}[3], ${$h{"5HSE202"}}[1]*20.1/31.05;
} # if ((${$h{"5EHSE106"}}[3]+1) % 2 == 0) {
$s .= sprintf "%3s<font color=%s>M Unload %6s</font></a>\n", 
               " ",${$h{AOUNLOAD}}[3], ${$h{AOUNLOAD}}[1];
$s .= sprintf '<a href="http://cxc.harvard.edu/mta/DAILY/mta_rt/iru_plot.html" STYLE="text-decoration: none" target="blank">';
$s .= sprintf "<font color=%s>Gyro 2 Curr 2 %6.2f</font></a>   ", 
               ${$h{AIRU2G2I}}[3], ${$h{AIRU2G2I}}[1];
$s .= sprintf '<a href="http://cxc.harvard.edu/mta/DAILY/mta_rt/iru_bias_plot.html" STYLE="text-decoration: none" target="blank">';
$s .= sprintf "<font color=%s>Roll Bias  %7.4f</font></a>", 
               ${$h{AOGBIAS1}}[3], ${$h{AOGBIAS1}}[1]*206264.98;
$s .= sprintf '<a href="http://cxc.harvard.edu/mta/DAILY/mta_rt/ctx_plot.html" STYLE="text-decoration: none" target="blank">';
$s .= sprintf "%23s<font color=%s>TSC Move %6s</font></a>\n",
               " ",${$h{"3TSCMOVE"}}[3], ${$h{"3TSCMOVE"}}[1];
$s .= sprintf '<a href="http://cxc.harvard.edu/mta/DAILY/mta_rt/iru_plot.html" STYLE="text-decoration: none" target="blank">';
$s .= sprintf "<font color=%s>Prop. line 03 %6.2f</font></a>   ",
               ${$h{PLINE03T}}[3], ${$h{PLINE03T}}[1];
$s .= sprintf '<a href="http://cxc.harvard.edu/mta/DAILY/mta_rt/iru_bias_plot.html" STYLE="text-decoration: none" target="blank">';
$s .= sprintf "<font color=%s>Pitch Bias %7.4f</font></a>", 
               ${$h{AOGBIAS2}}[3], ${$h{AOGBIAS2}}[1]*206264.98;
$s .= sprintf '<a href="http://cxc.harvard.edu/mta/DAILY/mta_rt/ctx_plot.html" STYLE="text-decoration: none" target="blank">';
if (${$h{CTXAPWR}}[1] > 15) {
  $s .= sprintf "  <font color=%s>CTX A PWR  %7.2f</font></a>", ${$h{CTXAPWR}}[3],${$h{CTXAPWR}}[1];
} else {
  $s .= sprintf "  <font color=%s>CTX B PWR  %7.2f</font></a>", ${$h{CTXBPWR}}[3],${$h{CTXBPWR}}[1];
}
$s .= sprintf "   <font color=%s>FA Move  %6s</font>\n",
               ${$h{"3FAMOVE"}}[3], ${$h{"3FAMOVE"}}[1];
$s .= sprintf '<a href="http://cxc.harvard.edu/mta/DAILY/mta_rt/iru_plot.html" STYLE="text-decoration: none" target="blank">';
$s .= sprintf "<font color=%s>Prop. line 04 %6.2f</font></a>", 
               ${$h{PLINE04T}}[3], ${$h{PLINE04T}}[1];
$s .= sprintf '<a href="http://cxc.harvard.edu/mta/DAILY/mta_rt/iru_bias_plot.html" STYLE="text-decoration: none" target="blank">';
$s .= sprintf "%3s<font color=%s>Yaw Bias   %7.4f</font></a>",
               " ",${$h{AOGBIAS3}}[3], ${$h{AOGBIAS3}}[1]*206264.98;
if (${$h{CTXAV}}[1] > 1) {
  $s .= sprintf "  <font color=%s>CTX A Volts  %5.2f</font>", ${$h{CTXAV}}[3],${$h{CTXAV}}[1];
} else {
  $s .= sprintf "  <font color=%s>CTX B Volts  %5.2f</font>", ${$h{CTXBV}}[3],${$h{CTXBV}}[1];
}
$s .= sprintf "%3s<font color=%s>OTG Move %6s</font>\n", 
               " ",${$h{"4OOTGMEF"}}[3], ${$h{"4OOTGMEF"}}[1];
$s .= sprintf "\n</a>\n";

return $s;

}

sub update_txt {
# if, we're LOS, just update the first line of the text version 
my %h;
%h = get_curr(%h);
$utc = `date -u +"%Y:%j:%T (%b%e)"`;
chomp $utc;
$h{UTC} = [time_now(), $utc, "", "white"];
my $s = sprintf "UTC %s f_ACE %.2e F_CRM %.2e Kp %.1f R km%7s%s\n",${$h{UTC}}[1],${$h{FLUXACE}}[1],${$h{CRM}}[1],${$h{KP}}[1],${$h{EPHEM_ALT}}[1],${$h{EPHEM_LEG}}[1];

$snapf = "$_[0]";
open(SF, "<$snapf") or die "Cannot open $snapf\n";
<SF>;   # skip first line, will be replaced by current
while (<SF>) {
  $s .= $_;
}
close SF;
open(SF,">$snapf") or die "Cannot create $snapf\n";
print SF $s;
close SF;
}

sub write_curr_wap {
  my %h = @_;

# construct the wireless snapshot page
my $s = "<\?xml version=\"1.0\"\?>\n";
$s .= "<!DOCTYPE wml PUBLIC \"-//WAPFORUM//DTD WML 1.1//EN\" \"http://www.wapforum.org/DTD/wml_1.1.xml\">\n";

$s .= "<wml>\n";

$s .= "<card id=\"current\">\n";
$s .= "<p>\n";
$s .= sprintf "UTC %s<br/>\n", ${$h{UTC}}[1];
$s .= sprintf "f_ACE %.2e<br/>\n", ${$h{FLUXACE}}[1];
#sprintf "F_ACE %.2e<br/>\n", #              ${$h{FLUACE}}[1];
$s .= sprintf "F_CRM %.2e<br/>\n", ${$h{CRM}}[1];
$s .= sprintf "Kp %.1f<br/>\n", ${$h{KP}}[1];
$s .= sprintf "R km%7s%s<br/>\n", ${$h{EPHEM_ALT}}[1],${$h{EPHEM_LEG}}[1];
$s .= "<a href=\"snap2.wml\">Index</a><br/>\n";
$s .= "</p></card>\n";
$s .= "</wml>\n";
return $s;
}

sub write_wap {
  my %h = @_;

my $wapdir = "/data/mta4/www/WL";

# construct the wireless snapshot page
open (S, ">$wapdir/snap2.wml");
printf S "<\?xml version=\'1.0\'\?>\n";
printf S "<!DOCTYPE wml PUBLIC \'-//WAPFORUM//DTD WML 1.1//EN\' \'http://www.wapforum.org/DTD/wml_1.1.xml\'>\n";
printf S "<wml>\n";
printf S "<card id=\'index\'>\n";
printf S "<p align=\'center\'>\n";
printf S "Chandra Snapshot<br/>\n";
printf S "<a href=\'snap_curr.wml\'>Current/Rad</a><br/>\n";
printf S "<a href=\'sccdm.wml\'>CCDM/OBC</a><br/>\n";
printf S "<a href=\'spcad.wml\'>PCAD/ACA</a><br/>\n";
printf S "<a href=\'seph.wml\'>EPHIN</a><br/>\n";
#printf S "<a href=\'sscs.wml\'>SCS/SW</a><br/>\n";
#printf S "<a href=\'saca.wml\'>ACA</a><br/>\n";
#printf S "<a href=\'ssim.wml\'>SIM/OTG</a><br/>\n";
printf S "<a href=\'ssim.wml\'>INST</a><br/>\n";
printf S "<a href=\'seps.wml\'>EPS/THERM</a><br/>\n";
#printf S "<a href=\'sacis.wml\'>ACIS</a><br/>\n";
#printf S "<a href=\'shrc.wml\'>HRC</a><br/>\n";
#printf S "<a href=\'sfss.wml\'>FSS/SA</a><br/>\n";
#printf S "<a href=\'shrma.wml\'>HRMA/OBA</a><br/>\n";
printf S "<br/>\n";
printf S "<a href=\'sot.wml\'>SOT Home</a><br/>\n";
printf S "</p>\n";
printf S "</card>\n";
printf S "</wml>\n";
close S;

open (S, ">$wapdir/sccdm.wml");
printf S "<\?xml version=\'1.0\'\?>\n";
printf S "<!DOCTYPE wml PUBLIC \'-//WAPFORUM//DTD WML 1.1//EN\' \'http://www.wapforum.org/DTD/wml_1.1.xml\'>\n";
printf S "<wml>\n";
printf S "<card id=\'index\'>\n";
printf S "<p>\n";
printf S "OBT %s<br/>\n", ${$h{OBT}}[1];
printf S "OBT %17.2f<br/>\n", ${$h{OBT}}[0];
printf S "CTUVCDU %8d<br/>\n", ${$h{CCSDSVCD}}[1];
printf S "ONLVCDU %8d<br/>\n", ${$h{OFLVCDCT}}[1];
printf S "OBC s/w %s<br/>\n", ${$h{CONLOFP}}[1];
printf S "OBC Errs%4d<br/>\n", ${$h{COERRCN}}[1];
printf S "%s_%-4s<br/>\n", ${$h{CCSDSTMF}}[1],${$h{COTLRDSF}}[1];
printf S "CPEstat %s<br/>\n", ${$h{AOCPESTL}}[1];
printf S "OBSID  %5d<br/>\n", ${$h{COBSRQID}}[1];
printf S "SCS 128  %4s<br/>\n", ${$h{COSCS128S}}[1];
printf S "SCS 129  %4s<br/>\n", ${$h{COSCS129S}}[1];
printf S "SCS 130  %4s<br/>\n", ${$h{COSCS130S}}[1];
printf S "SCS 107  %4s<br/>\n", ${$h{COSCS107S}}[1];
printf S "UpL CmdAcc%7d<br/>\n", ${$h{CULACC}}[1];
printf S "Cmd Rej A%9d<br/>\n", ${$h{CMRJCNTA}}[1];
printf S "<a href=\'snap2.wml\'>Index</a><br/>\n";
printf S "<a href=\'snap_curr.wml\'>Current</a><br/>\n";
printf S "</p></card>\n";
printf S "</wml>\n";
close S;

open (S, ">$wapdir/seps.wml");
printf S "<\?xml version=\'1.0\'\?>\n";
printf S "<!DOCTYPE wml PUBLIC \'-//WAPFORUM//DTD WML 1.1//EN\' \'http://www.wapforum.org/DTD/wml_1.1.xml\'>\n";
printf S "<wml>\n";
printf S "<card id=\'index\'>\n";
printf S "<p>\n";
printf S "EPState %4s<br/>\n", ${$h{EPSTATE}}[1];
printf S "Bus V %6.2f<br/>\n", ${$h{ELBV}}[1];
printf S "Bus I %6.2f<br/>\n", ${$h{ELBI_LOW}}[1];
printf S "Bat1SOC %7.2f%%<br/>\n", ${$h{SOCB1}}[1];
printf S "Bat2SOC %7.2f%%<br/>\n", ${$h{SOCB2}}[1];
printf S "Bat3SOC %7.2f%%<br/>\n", ${$h{SOCB3}}[1];
printf S "Avg HRMA T %6.2f<br/>\n", ${$h{"4OAVHRMT"}}[1];
printf S "Avg OBA T %6.2f<br/>\n", ${$h{"4OAVOBAT"}}[1];
printf S "OBA Tavg %s<br/>\n", ${$h{"4OBAVTMF"}}[1];
printf S "OBA Trng %s<br/>\n", ${$h{"4OBTOORF"}}[1];
printf S "HRMA pwr %7.2f<br/>\n", ${$h{OHRMAPWR}}[1];
printf S "OBA pwr %7.2f<br/>\n", ${$h{OOBAPWR}}[1];
printf S "<a href=\'snap2.wml'>Index</a><br/>\n";
printf S "<a href=\'snap_curr.wml'>Current</a><br/>\n";
printf S "</p></card>\n";
printf S "</wml>\n";
close S;

open (S, ">$wapdir/ssim.wml");
printf S "<\?xml version=\'1.0\'\?>\n";
printf S "<!DOCTYPE wml PUBLIC \'-//WAPFORUM//DTD WML 1.1//EN\' \'http://www.wapforum.org/DTD/wml_1.1.xml\'>\n";
printf S "<wml>\n";
printf S "<card id=\'index\'>\n";
printf S "<p>\n";
printf S "SIM TTpos %7d<br/>\n", ${$h{"3TSCPOS"}}[1];
printf S "SIM FApos %7d<br/>\n", ${$h{"3FAPOS"}}[1];
printf S "HETG Ang %6.2f<br/>\n", ${$h{"4HPOSARO"}}[1];
printf S "LETG Ang %6.2f<br/>\n", ${$h{"4LPOSBRO"}}[1];
printf S "TSC Move %6s<br/>\n", ${$h{"3TSCMOVE"}}[1];
printf S "FA Move %6s<br/>\n", ${$h{"3FAMOVE"}}[1];
printf S "OTG Move %6s<br/>\n", ${$h{"4OOTGMEF"}}[1];
printf S "ACIS Stat7-0 %s<br/>\n", ${$h{ACISTAT}}[1];
printf S "Cold Rad %6.1f<br/>\n", ${$h{"1CRAT"}}[1];
printf S "Warm Rad %6.1f<br/>\n", ${$h{"1WRAT"}}[1];
printf S "HRC-I HV %3s<br/>\n", ${$h{"2IMONST"}}[1];
printf S "HRC-S HV %3s<br/>\n", ${$h{"2SPONST"}}[1];
printf S "OBSMode %4s<br/>\n", ${$h{"2OBNLASL"}}[1];
printf S "SHLD HV %4.1f<br/>\n", ${$h{"2S2HVST"}}[1];
printf S "EVT RT  %4d<br/>\n", ${$h{"2DETART"}}[1];
printf S "SHLD RT %4d<br/>\n", ${$h{"2SHLDART"}}[1];
printf S "<a href=\'snap2.wml'>Index</a><br/>\n";
printf S "<a href=\'snap_curr.wml'>Current</a><br/>\n";
printf S "</p></card>\n";
printf S "</wml>\n";
close S;

open (S, ">$wapdir/spcad.wml");
printf S "<\?xml version=\'1.0\'\?>\n";
printf S "<!DOCTYPE wml PUBLIC \'-//WAPFORUM//DTD WML 1.1//EN\' \'http://www.wapforum.org/DTD/wml_1.1.xml\'>\n";
printf S "<wml>\n";
printf S "<card id=\'index\'>\n";
printf S "<p>\n";
printf S "PCADMODE %s<br/>\n", ${$h{AOPCADMD}}[1];
printf S "PCONTROL %s<br/>\n", ${$h{AOCONLAW}}[1];
printf S "AOFSTAR  %s<br/>\n", ${$h{AOFSTAR}}[1];
printf S "RA   %7.3f<br/>\n", ${$h{RA}}[1];
printf S "Dec  %7.3f<br/>\n", ${$h{DEC}}[1];
printf S "Roll %7.3f<br/>\n", ${$h{ROLL}}[1];
printf S "Dither  %s<br/>\n", ${$h{AODITHEN}}[1];
printf S "Dith Yang %6.2f<br/>\n", ${$h{AODITHR3}}[1];
printf S "Dith Zang %6.2f<br/>\n", ${$h{AODITHR2}}[1];
printf S "Yaw Rate   %7.2f<br/>\n", ${$h{AORATE3}}[1];
printf S "Ptch Rate %7.2f<br/>\n", ${$h{AORATE2}}[1];
printf S "Roll Rate  %7.2f<br/>\n", ${$h{AORATE1}}[1];
printf S "Yaw Mom   %8.3f<br/>\n", ${$h{AOSYMOM3}}[1];
printf S "Ptch Mom %8.3f<br/>\n", ${$h{AOSYMOM2}}[1];
printf S "Roll Mom  %8.3f<br/>\n", ${$h{AOSYMOM1}}[1];
printf S "Mom. Unl. %6s<br/>\n", ${$h{AOUNLOAD}}[1];
printf S "ACA Ob %s<br/>\n", ${h{ACAOBJ}}[1];
printf S "ACA Im %s<br/>\n", ${$h{ACAFCT}}[1];
printf S "ACA CCD T %6.1f<br/>\n", ${$h{AACCCDPT}}[1];
printf S "ACA Int s %6.3f<br/>\n", ${$h{AOACINTT}}[1];
printf S "AOACSTAT       %4s<br/>\n", ${$h{AOACSTAT}}[1];
printf S "FSS SunBeta %4s<br/>\n", ${$h{AOBETSUN}}[1];
printf S "FSS Alfa  %6.2f<br/>\n", ${$h{AOALPANG}}[1];
printf S "FSS Beta  %6.2f<br/>\n", ${$h{AOBETANG}}[1];
printf S "SA Resolv %6.2f<br/>\n", ${$h{AOSARES1}}[1];
printf S "SA SunPres %4s<br/>\n", ${$h{AOSAILLM}}[1];
printf S "+Y SA I %7.2f<br/>\n", ${$h{ESAPYI}}[1];
printf S "-Y SA I %7.2f<br/>\n", ${$h{ESAMYI}}[1];
printf S "+Y SA T %7.2f<br/>\n", ${$h{TSAPYT}}[1];
printf S "-Y SA T %7.2f<br/>\n", ${$h{TSAMYT}}[1];
printf S "G1 Curr1 %6.2f<br/>\n", ${$h{AIRU1G1I}}[1];
printf S "G1 Curr2 %6.2f<br/>\n", ${$h{AIRU1G2I}}[1];
printf S "G2 Curr1 %6.2f<br/>\n", ${$h{AIRU2G1I}}[1];
printf S "G2 Curr2 %6.2f<br/>\n", ${$h{AIRU2G2I}}[1];
printf S "Pline03T %6.2f<br/>\n", ${$h{PLINE03T}}[1];
printf S "Pline04T %6.2f<br/>\n", ${$h{PLINE04T}}[1];
printf S "<a href=\'snap2.wml'>Index</a><br/>\n";
printf S "<a href=\'snap_curr.wml'>Current</a><br/>\n";
printf S "</p></card>\n";
printf S "</wml>\n";
close S;

open (S, ">$wapdir/seph.wml");
printf S "<\?xml version=\'1.0\'\?>\n";
printf S "<!DOCTYPE wml PUBLIC \'-//WAPFORUM//DTD WML 1.1//EN\' \'http://www.wapforum.org/DTD/wml_1.1.xml\'>\n";
printf S "<wml>\n";
printf S "<card id=\'index\'>\n";
printf S "<p>\n";
printf S "RadMon     %4s<br/>\n", ${$h{CORADMEN}}[1];
printf S "EPHIN Geom %4s<br/>\n", ${$h{GEOM}}[1];
printf S "E150%11.1f<br/>\n", ${$h{E150}}[1];
printf S "E300%11.1f<br/>\n", ${$h{E300}}[1];
printf S "E1300%10.1f<br/>\n", ${$h{E1300}}[1];
printf S "P4GM%11.1f<br/>\n", ${$h{P4GM}}[1];
printf S "P41GM%10.1f<br/>\n", ${$h{P41GM}}[1];
printf S "EPHALeak%8.4f<br/>\n", ${$h{ALEAK}}[1];
printf S "EPHBLeak%8.4f<br/>\n", ${$h{"5EHSE500"}}[1];
printf S "EPHTemp%8.2f<br/>\n", ${$h{TEPHIN}}[1];
#printf S "EPH27I%8.2f<br/>\n", ${$h{"5HSE202"}}[1];
#printf S "EPH27V%8.2f<br/>\n", ${$h{ACV_P27V}}[1];
printf S "<a href=\'snap2.wml'>Index</a><br/>\n";
printf S "<a href=\'snap_curr.wml'>Current</a><br/>\n";
printf S "</p></card>\n";
printf S "</wml>\n";
close S;

}

sub write_curr_wap_arc {
  my %h = @_;

# construct the wireless snapshot archive
#  text only, to be interpreted and browsed with cgi script
my $s = sprintf "UTC %s \*%1s\n", ${$h{UTC}}[1], ${$h{UTC}}[2];
$s .= sprintf "f_ACE %.2e \*%1s\n", ${$h{FLUXACE}}[1], ${$h{FLUXACE}}[2];
#sprintf "F_ACE %.2e \*%1s\n", #              ${$h{FLUACE}}[1], ${$h{FLUACE}}[2];
$s .= sprintf "F_CRM %.2e \*%1s\n", ${$h{CRM}}[1], ${$h{CRM}}[2];
$s .= sprintf "Kp %.1f \*%1s\n", ${$h{KP}}[1], ${$h{KP}}[2];
$s .= sprintf "R km%7s%s \*%1s\n", ${$h{EPHEM_ALT}}[1],${$h{EPHEM_LEG}}[1], ${$h{EPHEM_ALT}}[2];
return $s;
}

sub write_wap_arc {
  my %h = @_;

# construct the wireless snapshot archive
#  text only, to be interpreted and browsed with cgi script

my $wapdir = "/data/mta4/www/WL/Snap_dat";

$date = sprintf "%4d%3.3d",$y+1900,$yday+1;
   
open (S, ">>$wapdir/sccdm.$date");
printf S "UTC %s \*%1s\n", ${$h{UTC}}[1], ${$h{UTC}}[2];
printf S "OBT %s \*%1s\n", ${$h{OBT}}[1], ${$h{OBT}}[2];
printf S "OBT %17.2f \*%1s\n", ${$h{OBT}}[0], ${$h{OBT}}[2];
printf S "CTUVCDU %8d \*%1s\n", ${$h{CCSDSVCD}}[1], ${$h{CCSDSVCD}}[2];
printf S "ONLVCDU %8d \*%1s\n", ${$h{OFLVCDCT}}[1], ${$h{OFLVCDCT}}[2];
printf S "OBC s/w %s \*%1s\n", ${$h{CONLOFP}}[1], ${$h{CONLOFP}}[2];
printf S "OBC Errs%4d \*%1s\n", ${$h{COERRCN}}[1], ${$h{COERRCN}}[2];
printf S "%s_%-4s \*%1s\n", ${$h{CCSDSTMF}}[1],${$h{COTLRDSF}}[1], ${$h{CCSDSTMF}}[2];
printf S "CPEstat %s \*%1s\n", ${$h{AOCPESTL}}[1], ${$h{AOCPESTL}}[2];
printf S "OBSID  %5d \*%1s\n", ${$h{COBSRQID}}[1], ${$h{COBSRQID}}[2];
printf S "SCS 128  %4s \*%1s\n", ${$h{COSCS128S}}[1], ${$h{COSCS128S}}[2];
printf S "SCS 129  %4s \*%1s\n", ${$h{COSCS129S}}[1], ${$h{COSCS129S}}[2];
printf S "SCS 130  %4s \*%1s\n", ${$h{COSCS130S}}[1], ${$h{COSCS130S}}[2];
printf S "SCS 107  %4s \*%1s\n", ${$h{COSCS107S}}[1], ${$h{COSCS107S}}[2];
printf S "UpL CmdAcc%7d \*%1s\n", ${$h{CULACC}}[1], ${$h{CULACC}}[2];
printf S "Cmd Rej A%9d \*%1s\n", ${$h{CMRJCNTA}}[1], ${$h{CMRJCNTA}}[2];
close S;

open (S, ">>$wapdir/seps.$date");
printf S "UTC %s \*%1s\n", ${$h{UTC}}[1], ${$h{UTC}}[2];
printf S "OBT %s \*%1s\n", ${$h{OBT}}[1], ${$h{OBT}}[2];
printf S "EPState %4s \*%1s\n", ${$h{EPSTATE}}[1], ${$h{EPSTATE}}[2];
printf S "Bus V %6.2f \*%1s\n", ${$h{ELBV}}[1], ${$h{ELBV}}[2];
printf S "Bus I %6.2f \*%1s\n", ${$h{ELBI_LOW}}[1], ${$h{ELBI_LOW}}[2];
printf S "Bat1SOC %7.2f%% \*%1s\n", ${$h{SOCB1}}[1], ${$h{SOCB1}}[2];
printf S "Bat2SOC %7.2f%% \*%1s\n", ${$h{SOCB2}}[1], ${$h{SOCB2}}[2];
printf S "Bat3SOC %7.2f%% \*%1s\n", ${$h{SOCB3}}[1], ${$h{SOCB3}}[2];
printf S "Avg HRMA T %6.2f \*%1s\n", ${$h{"4OAVHRMT"}}[1], ${$h{"4OAVHRMT"}}[2];
printf S "Avg OBA T %6.2f \*%1s\n", ${$h{"4OAVOBAT"}}[1], ${$h{"4OAVOBAT"}}[2];
printf S "OBA Tavg %s \*%1s\n", ${$h{"4OBAVTMF"}}[1], ${$h{"4OBAVTMF"}}[2];
printf S "OBA Trng %s \*%1s\n", ${$h{"4OBTOORF"}}[1], ${$h{"4OBTOORF"}}[2];
printf S "HRMA pwr %7.2f \*%1s\n", ${$h{OHRMAPWR}}[1], ${$h{OHRMAPWR}}[2];
printf S "OBA pwr %7.2f \*%1s\n", ${$h{OOBAPWR}}[1], ${$h{OOBAPWR}}[2];
close S;

open (S, ">>$wapdir/ssim.$date");
printf S "UTC %s \*%1s\n", ${$h{UTC}}[1], ${$h{UTC}}[2];
printf S "OBT %s \*%1s\n", ${$h{OBT}}[1], ${$h{OBT}}[2];
printf S "SIM TTpos %7d \*%1s\n", ${$h{"3TSCPOS"}}[1], ${$h{"3TSCPOS"}}[2];
printf S "SIM FApos %7d \*%1s\n", ${$h{"3FAPOS"}}[1], ${$h{"3FAPOS"}}[2];
printf S "HETG Ang %6.2f \*%1s\n", ${$h{"4HPOSARO"}}[1], ${$h{"4HPOSARO"}}[2];
printf S "LETG Ang %6.2f \*%1s\n", ${$h{"4LPOSBRO"}}[1], ${$h{"4LPOSBRO"}}[2];
printf S "TSC Move %6s \*%1s\n", ${$h{"3TSCMOVE"}}[1], ${$h{"3TSCMOVE"}}[2];
printf S "FA Move %6s \*%1s\n", ${$h{"3FAMOVE"}}[1], ${$h{"3FAMOVE"}}[2];
printf S "OTG Move %6s \*%1s\n", ${$h{"4OOTGMEF"}}[1], ${$h{"4OOTGMEF"}}[2];
printf S "ACIS Stat7-0 %s \*%1s\n", ${$h{ACISTAT}}[1], ${$h{ACISTAT}}[2];
printf S "Cold Rad %6.1f \*%1s\n", ${$h{"1CRAT"}}[1], ${$h{"1CRAT"}}[2];
printf S "Warm Rad %6.1f \*%1s\n", ${$h{"1WRAT"}}[1], ${$h{"1WRAT"}}[2];
printf S "HRC-I HV %3s \*%1s\n", ${$h{"2IMONST"}}[1], ${$h{"2IMONST"}}[2];
printf S "HRC-S HV %3s \*%1s\n", ${$h{"2SPONST"}}[1], ${$h{"2SPONST"}}[2];
printf S "OBSMode %4s \*%1s\n", ${$h{"2OBNLASL"}}[1], ${$h{"2OBNLASL"}}[2];
printf S "SHLD HV %4.1f \*%1s\n", ${$h{"2S2HVST"}}[1], ${$h{"2S2HVST"}}[2];
printf S "EVT RT  %4d \*%1s\n", ${$h{"2DETART"}}[1], ${$h{"2DETART"}}[2];
printf S "SHLD RT %4d \*%1s\n", ${$h{"2SHLDART"}}[1], ${$h{"2SHLDART"}}[2];
close S;

open (S, ">>$wapdir/spcad.$date");
printf S "UTC %s \*%1s\n", ${$h{UTC}}[1], ${$h{UTC}}[2];
printf S "OBT %s \*%1s\n", ${$h{OBT}}[1], ${$h{OBT}}[2];
printf S "PCADMODE %s \*%1s\n", ${$h{AOPCADMD}}[1], ${$h{AOPCADMD}}[2];
printf S "PCONTROL %s \*%1s\n", ${$h{AOCONLAW}}[1], ${$h{AOCONLAW}}[2];
printf S "AOFSTAR  %s \*%1s\n", ${$h{AOFSTAR}}[1], ${$h{AOFSTAR}}[2];
printf S "RA   %7.3f \*%1s\n", ${$h{RA}}[1], ${$h{RA}}[2];
printf S "Dec  %7.3f \*%1s\n", ${$h{DEC}}[1], ${$h{DEC}}[2];
printf S "Roll %7.3f \*%1s\n", ${$h{ROLL}}[1], ${$h{ROLL}}[2];
printf S "Dither  %s \*%1s\n", ${$h{AODITHEN}}[1], ${$h{AODITHEN}}[2];
printf S "Dith Yang %6.2f \*%1s\n", ${$h{AODITHR3}}[1], ${$h{AODITHR3}}[2];
printf S "Dith Zang %6.2f \*%1s\n", ${$h{AODITHR2}}[1], ${$h{AODITHR2}}[2];
printf S "Yaw Rate   %7.2f \*%1s\n", ${$h{AORATE3}}[1], ${$h{AORATE3}}[2];
printf S "Ptch Rate %7.2f \*%1s\n", ${$h{AORATE2}}[1], ${$h{AORATE2}}[2];
printf S "Roll Rate  %7.2f \*%1s\n", ${$h{AORATE1}}[1], ${$h{AORATE1}}[2];
printf S "Yaw Mom   %8.3f \*%1s\n", ${$h{AOSYMOM3}}[1], ${$h{AOSYMOM3}}[2];
printf S "Ptch Mom %8.3f \*%1s\n", ${$h{AOSYMOM2}}[1], ${$h{AOSYMOM2}}[2];
printf S "Roll Mom  %8.3f \*%1s\n", ${$h{AOSYMOM1}}[1], ${$h{AOSYMOM1}}[2];
printf S "Mom. Unl. %6s \*%1s\n", ${$h{AOUNLOAD}}[1], ${$h{AOUNLOAD}}[2];
printf S "ACA Ob %s \*%1s\n", ${h{ACAOBJ}}[1], ${h{ACAOBJ}}[2];
printf S "ACA Im %s \*%1s\n", ${$h{ACAFCT}}[1], ${$h{ACAFCT}}[2];
printf S "ACA CCD T %6.1f \*%1s\n", ${$h{AACCCDPT}}[1], ${$h{AACCCDPT}}[2];
printf S "ACA Int s %6.3f \*%1s\n", ${$h{AOACINTT}}[1], ${$h{AOACINTT}}[2];
printf S "AOACSTAT       %4s \*%1s\n", ${$h{AOACSTAT}}[1], ${$h{AOACSTAT}}[2];
printf S "FSS SunBeta %4s \*%1s\n", ${$h{AOBETSUN}}[1], ${$h{AOBETSUN}}[2];
printf S "FSS Alfa  %6.2f \*%1s\n", ${$h{AOALPANG}}[1], ${$h{AOALPANG}}[2];
printf S "FSS Beta  %6.2f \*%1s\n", ${$h{AOBETANG}}[1], ${$h{AOBETANG}}[2];
printf S "SA Resolv %6.2f \*%1s\n", ${$h{AOSARES1}}[1], ${$h{AOSARES1}}[2];
printf S "SA SunPres %4s \*%1s\n", ${$h{AOSAILLM}}[1], ${$h{AOSAILLM}}[2];
printf S "+Y SA I %7.2f \*%1s\n", ${$h{ESAPYI}}[1], ${$h{ESAPYI}}[2];
printf S "-Y SA I %7.2f \*%1s\n", ${$h{ESAMYI}}[1], ${$h{ESAMYI}}[2];
printf S "+Y SA T %7.2f \*%1s\n", ${$h{TSAPYT}}[1], ${$h{TSAPYT}}[2];
printf S "-Y SA T %7.2f \*%1s\n", ${$h{TSAMYT}}[1], ${$h{TSAMYT}}[2];
printf S "G1 Curr1 %7.2f \*%1s\n", ${$h{AIRU1G1I}}[1], ${$h{AIRU1G1I}}[2];
printf S "G1 Curr2 %7.2f \*%1s\n", ${$h{AIRU1G2I}}[1], ${$h{AIRU1G2I}}[2];
printf S "G2 Curr1 %7.2f \*%1s\n", ${$h{AIRU2G1I}}[1], ${$h{AIRU2G1I}}[2];
printf S "G2 Curr2 %7.2f \*%1s\n", ${$h{AIRU2G2I}}[1], ${$h{AIRU2G2I}}[2];
printf S "Pline03T %7.2f \*%1s\n", ${$h{PLINE03T}}[1], ${$h{PLINE03T}}[2];
printf S "Pline04T %7.2f \*%1s\n", ${$h{PLINE04T}}[1], ${$h{PLINE04T}}[2];
close S;

open (S, ">>$wapdir/seph.$date");
printf S "UTC %s \*%1s\n", ${$h{UTC}}[1], ${$h{UTC}}[2];
printf S "OBT %s \*%1s\n", ${$h{OBT}}[1], ${$h{OBT}}[2];
printf S "RadMon     %4s \*%1s\n", ${$h{CORADMEN}}[1], ${$h{CORADMEN}}[2];
printf S "EPHIN Geom %4s \*%1s\n", ${$h{GEOM}}[1], ${$h{GEOM}}[2];
printf S "E150%11.1f \*%1s\n", ${$h{E150}}[1], ${$h{E150}}[2];
printf S "E300%11.1f \*%1s\n", ${$h{E300}}[1], ${$h{E300}}[2];
printf S "E1300%10.1f \*%1s\n", ${$h{E1300}}[1], ${$h{E1300}}[2];
printf S "P4GM%11.1f \*%1s\n", ${$h{P4GM}}[1], ${$h{P4GM}}[2];
printf S "P41GM%10.1f \*%1s\n", ${$h{P41GM}}[1], ${$h{P41GM}}[2];
printf S "EPHALeak%8.4f \*%1s\n", ${$h{ALEAK}}[1], ${$h{ALEAK}}[2];
printf S "EPHBLeak%8.4f \*%1s\n", ${$h{"5EHSE500"}}[1], ${$h{"5EHSE500"}}[2];
printf S "EPHTemp%8.2f \*%1s\n", ${$h{TEPHIN}}[1],${$h{TEPHIN}}[2];
close S;

# make red and yellow lists
my $red = '';
my $yel = '';
my $sta = '';
foreach $key (keys(%h)) {
  if ($h{$key}[2] eq 'R') { $red .= "$key $h{$key}[1] \*R\n"; next;}
  if ($h{$key}[2] eq 'Y') { $yel .= "$key $h{$key}[1] \*Y\n"; }
  if ($h{$key}[2] eq 'S') { $sta .= "$key $h{$key}[1] \*S\n"; }
  if ($h{$key}[2] eq 'I') { $sta .= "$key $h{$key}[1] \*I\n"; }
}
if ($red ne '') {
  open(S, ">>$wapdir/red.$date");
  printf S "UTC %s \*%1s\n", ${$h{UTC}}[1], ${$h{UTC}}[2];
  printf S "OBT %s \*%1s\n", ${$h{OBT}}[1], ${$h{OBT}}[2];
  print S $red;
  close S;
}
if ($yel ne '') {
  open(S, ">>$wapdir/yellow.$date");
  printf S "UTC %s \*%1s\n", ${$h{UTC}}[1], ${$h{UTC}}[2];
  printf S "OBT %s \*%1s\n", ${$h{OBT}}[1], ${$h{OBT}}[2];
  print S $yel;
  close S;
}
if ($sta ne '') {
  open(S, ">>$wapdir/stale.$date");
  printf S "UTC %s \*%1s\n", ${$h{UTC}}[1], ${$h{UTC}}[2];
  printf S "OBT %s \*%1s\n", ${$h{OBT}}[1], ${$h{OBT}}[2];
  print S $sta;
  close S;
}
} # end write_wap_arc
1;
