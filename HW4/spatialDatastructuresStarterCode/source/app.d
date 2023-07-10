import std.stdio;

import common;
import dumbknn;
import bucketknn;
//import your files here
import quadtree;
import kdtree;

void main()
{

    //because dim is a "compile time parameter" we have to use "static foreach"
    //to loop through all the dimensions we want to test.
    //the {{ are necessary because this block basically gets copy/pasted with
    //dim filled in with 1, 2, 3, ... 7.  The second set of { lets us reuse
    //variable names.
    //


     File file = File("dumb_knn.csv", "w");
     file.writeln("dumb_knn,dimension,n,k,time");
     writeln("DumbKNN results");
     static foreach (dim; 1..8) {{
         foreach (n; 1..8) {
             auto trainingPoints = getGaussianPoints!dim(n * 1000);
             auto testingPoints =  getUniformPoints!dim(100);
             auto dumb = DumbKNN!dim(trainingPoints);
             writeln("tree of dimension ", dim, " built");
             foreach (k; 1..11) {{
                 auto sw = StopWatch(AutoStart.no);
                 sw.start;
                 foreach (r; 1..4) {
                     foreach(const ref qp; testingPoints) {
                         dumb.knnQuery(qp, k * 100);
                     }
                 }
                 sw.stop;
                 file.writeln("dumb_knn", ",", dim, ",", n * 1000, ",", k * 100, ",", sw.peek.total!"usecs" / 300);
             }}
         }
     }}
     file.close();

     File file1 = File("bucket_knn.csv", "w");
     file1.writeln("bucket_knn,dimension,n,k,time");
     writeln("BucketKNN results");
     static foreach (Dim; 1..8) {{
         foreach (n; 1..4) {{
             enum numTrainingPoints = 1000;

             auto trainingPoints = getGaussianPoints!Dim(numTrainingPoints);
             auto testingPoints = getUniformPoints!Dim(100);

             auto bucket = BucketKNN!Dim(trainingPoints, cast(int) pow(numTrainingPoints / 64, 1.0 / Dim)); //rough estimate to get 64 points per cell on average

             writeln("tree of dimension ", Dim, " built");
             foreach (k; 1..6) {{
                 auto sw = StopWatch(AutoStart.no);
                 sw.start;
                 foreach (r; 1..10) {
                     foreach(const ref qp; testingPoints) {
                         bucket.knnQuery(qp, k * 100);
                     }
                 }
                 sw.stop;
                 file1.writeln("bucket_knn", ",", Dim, ",", n * 1000, ",", k * 100, ",", sw.peek.total!"usecs" / 300);
             }}
         }}
     }}
     file1.close();

     File file2 = File("quad_tree.csv", "w");
     file2.writeln("quad_tree,dimension,n,k,time");
     writeln("QuadTree results");
     foreach (n; 1..8) {
         auto trainingPoints = getGaussianPoints!2(n * 100000);
         auto testingPoints = getUniformPoints!2(100);

         //auto qt = QuadTree(trainingPoints);
         auto quad = QuadTree!2(trainingPoints, boundingBox(trainingPoints));
         foreach (k; 1..8) {{
             StopWatch sw = StopWatch(AutoStart.no);
             sw.start;
             foreach (r; 1..4) {
                 foreach (const ref qp; testingPoints) {
                     quad.knnQuery(qp, k * 100);
                 }
             }
             sw.stop;
             file2.writeln("quad_tree", ",", "2", ",", n * 100000, ",", k * 100, ",", sw.peek.total!"usecs" / 300);
         }}
     }
     file2.close();


     File file3 = File("kd_tree.csv", "w");
     file3.writeln("kd_tree,dimension,n,k,time");
     writeln("KDTree results");
     static foreach (Dim; 1..8) {{
         foreach (n; 1..8) {{
             auto testingPoints = getUniformPoints!Dim(10);
             auto trainingPoints = getGaussianPoints!Dim(n * 10000);
             auto kd = KDTree!Dim(trainingPoints);
             foreach (k; 1..11) {{
                 StopWatch sw;
                 sw.start;
                 foreach (r; 1..4) {
                     foreach (const ref qp; testingPoints) {
                         kd.knnQuery(qp, k * 100);
                     }
                     writeln("tree of dimension ", Dim, " built");
                 }
                 sw.stop;
                 file3.writeln("kd_tree", ",", Dim, ",", n * 10000, ",", k * 100, ",", sw.peek.total!"usecs" / 300);
             }}
         }}
     }}
     file3.close();


    //writeln("BucketKNN results");
    ////Same tests for the BucketKNN
    //static foreach(dim; 1..8){{
    //    //get points of the appropriate dimension
    //    enum numTrainingPoints = 1000;
    //    auto trainingPoints = getGaussianPoints!dim(numTrainingPoints);
    //    auto testingPoints = getUniformPoints!dim(100);
    //    auto kd = BucketKNN!dim(trainingPoints, cast(int)pow(numTrainingPoints/64, 1.0/dim)); //rough estimate to get 64 points per cell on average
    //    writeln("tree of dimension ", dim, " built");
    //    auto sw = StopWatch(AutoStart.no);
    //    sw.start; //start my stopwatch
    //    foreach(const ref qp; testingPoints){
    //        kd.knnQuery(qp, 10);
    //    }
    //    sw.stop;
    //    writeln(dim, sw.peek.total!"usecs"); //output the time elapsed in microseconds
    //    //NOTE, I SOMETIMES GOT TOTALLY BOGUS TIMES WHEN TESTING WITH DMD
    //    //WHEN YOU TEST WITH LDC, YOU SHOULD GET ACCURATE TIMING INFO...
    //}}
}
