#!/usr/local/bin/gawk -f
{
 printf "%.3f\n", smooth($1,$2,$3)

}
function smooth(a,b,c){
 tsmt = b;
 if((a!=0.0) && (b!=0.0) && (c!=0.0)){
   tsmt = (a + c)/4 + b/2;
 }
 return tsmt;
}

