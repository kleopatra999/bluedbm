set term postscript monochrome enhanced font "Helvetica" 16 butt dashed
set ylabel "Throughput" offset 2,0 font "Helvetica,20"
set xlabel "Threads" offset 2,0 font "Helvetica,20"
set ytics nomirror 
set xrange [0.8:16]
set yrange [0:700]

set grid ytics lc rgb "#cccccc" lt 0
set border lw 4

set key on inside top left width 2 samplen 4 spacing 1.5
set style fill pattern
set style data histograms
set size square

set output "hammingfull.ps"
plot 'hammingfull.dat' u 1:2 title col w linespoints lw 4 ps 1 pt 2, \
     'hammingfull.dat' u 1:3 title col w lines lw 4, \
     'hammingfull.dat' u 1:5 title col w linespoints lw 4 ps 1 pt 6




