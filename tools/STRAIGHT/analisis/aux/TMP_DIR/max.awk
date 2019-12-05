#!/usr/local/bin/gawk -f
{
 printf "%.3f\n", mid($1,$2,$3)

}
function max(a,b,c){
 tmax = a;
 if(tmax<b){
   tmax=b;
 }
 if(tmax<c){
   tmax=c;
 }
 return tmax;
}

function min(a,b,c){
 tmin = a;
 if(tmin>b){
   tmin=b;
 }
 if(tmin>c){
   tmin=c;
 }
 return tmin;
}

function mid(a,b,c){
 f0[1] = a;
 f0[2] = b;
 f0[3] = c;

 sort(f0,3);
 return f0[2];
}

# sort function -- sort numbers in ascending order
function sort(ARRAY, ELEMENTS, temp, i, j) {
   for (i = 2; i <= ELEMENTS; ++i) {
      for (j = i; ARRAY[j-1] > ARRAY[j]; --j) { 
           temp = ARRAY[j]
           ARRAY[j] = ARRAY[j-1]
           ARRAY[j-1] = temp
      }
   }
   return 
}

