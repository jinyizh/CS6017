import common;

struct QuadTree(size_t Dim) {
    // One way in which this is simpler than the others is that it only works in 2D.
    // I added
    alias P2 = Point!2;
    alias AABB2 = AABB!2;
    // at the top of my struct for convenience.

    class Node {
        // Your node class will store:
        P2[] points; // - A list of points (if it's a leaf node)
        Node nw, ne, sw, se; // - 4 children (if it's an internal node). Note, some of the children might be null.
        AABB2 aabb; // - An AABB that explains what area this node covers
        bool isLeaf; // and a boolean to tell you whether or not it's a leaf.

        this(P2[] points, AABB2 aabb) {
            // The Node constructor should take a list of points and an AABB describing what area it covers
            // It will recursively call itself when constructing children (if necessary)
            if (points.length <= 64) {
                isLeaf = true;
                this.points = points.dup;
                this.aabb = aabb;
            }
            else {
                isLeaf = false;
                P2 midpoint = (aabb.max + aabb.min) / 2;
                auto rightPart = points.partitionByDimension!0(midpoint[0]);
                auto leftPart = points[0 .. $ - rightPart.length];

                auto nws = leftPart.partitionByDimension!1(midpoint[1]);
                auto nes = rightPart.partitionByDimension!1(midpoint[1]);
                auto sws = leftPart[0 .. $ - nws.length];
                auto ses = rightPart[0 .. $ - nes.length];

                nw = new Node(nws, boundingBox(nws));
                ne = new Node(nes, boundingBox(nes));
                sw = new Node(sws, boundingBox(sws));
                se = new Node(ses, boundingBox(ses));
            }
        }
    }

    // The Quadtree struct itself will then just store a Node root.
    private Node root;

    this(Point!2[] points, AABB!2 aabb) {
        this.root = new Node(points, aabb);
    }

    // For the query methods, I recommend defining a nested function for recursion:
    P2[] rangeQuery(Point!2 p, float r) {
        P2[] ret;
        void recurse(Node n) {
            if (n.isLeaf) {
                foreach (const ref point; n.points) {
                    if (distance(p, point) < r) {
                        ret ~= point;
                    }
                }
            }
            else {
                auto children = [n.nw, n.ne, n.sw, n.se];
                foreach (child; children) {
                    auto point = closest(child.aabb, p);
                    if (distance(p, point) < r) {
                        recurse(child);
                    }
                }
            }
        }
        recurse(root);
        return ret;
    }

    P2[] knnQuery(P2 p, int k) {
        P2[] ret;
        auto pq = makePriorityQueue(p);
        void recurse (Node node){
            if (node.isLeaf == true) {
                foreach(const ref q; node.points){
                    if (pq.length < k){
                        pq.insert(q);
                    }
                    else if (distance(p, q) < distance(p, pq.front)){
                        pq.popFront;
                        pq.insert(q);
                    }
                }
            }
            else {
                auto children = [node.nw, node.ne, node.sw, node.se];
                foreach (child; children) {
                    auto point = closest(child.aabb, p);
                    if ((node.points.length < k) || (distance(p, point) < distance(p, pq.front))) {
                        recurse(child);
                    }
                }
            }
        }
        recurse (root);
        foreach (const ref point; pq){
            ret ~= point;
        }
        return ret;
    }
}


unittest {
    auto points = [Point!2([.5, .5]), Point!2([1, 1]), Point!2([0.75, 0.4]), Point!2([0.4, 0.74])];
    auto qt = QuadTree(points);

    writeln("quadtree ranre query");
    foreach(p; qt.rangeQuery(Point!2([1,1]), .7)) {
        writeln(p);
    }

    writeln("quadtree knn");
    foreach(p; qt.knnQuery(Point!2([1,1]), 3)) {
        writeln(p);
    }
}