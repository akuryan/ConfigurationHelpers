sc config "smtpsvc"  start= auto
sc failure "smtpsvc"  actions= restart/180000/restart/180000/""/180000 reset= 43400