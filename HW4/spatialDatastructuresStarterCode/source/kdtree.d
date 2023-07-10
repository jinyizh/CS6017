import common;

/*
 This is similar to the quadtree except that the Node class should take a compile-time int parameter
 specifying which dimension it "split's" on
 (does it split points based on point[0] (the x-coordinate), point[1] (the y-coordinate), point[2](the z-coordinate), etc).
 Using a compile-time parameter here saves memory (it doesn't need to be stored at runtime),
 and it can make sure we catch bugs related to using the wrong type of node at compile time.
 Here's some code snippets that might help with the tricky bits:
 */

// An x-split node and a y-split node are different types
struct KDTree(size_t Dim) {
    class Node(size_t splitDimension) {
        // If this is an x node, the next level is "y"
        // If this is a y node, the next level is "z", etc
        enum thisLevel = splitDimension; // This lets you refer to a node's split level with theNode.thisLevel
        enum nextLevel = (splitDimension + 1) % Dim;
        Node!nextLevel left, right; // Child nodes split by the next level

        Point!Dim splitpoint; // stored as member variable

        this(Point!Dim[] points) {
            points.medianByDimension!thisLevel;
            int median = cast(int) points.length / 2;
            splitpoint = points[median];
            auto leftPart = points[0 .. median];
            auto rightPart = points[median + 1 .. $];
            if (leftPart.length > 0) {
                left = new Node!nextLevel(leftPart);
            }
            if (rightPart.length > 0) {
                right = new Node!nextLevel(rightPart);
            }
        }
    }

    private Node!0 root;

    this(Point!Dim[] points) {
        root = new Node!0(points);
    }

    Point!Dim[] rangeQuery(Point!Dim p, float r) {
        Point!Dim[] ret;
        void recurse(size_t splitDimension)(Node!splitDimension n) {
            if (distance(p, n.splitpoint) < r) {
                ret ~= n.splitpoint;
            }
            if (p[splitDimension] - r <= n.splitpoint[splitDimension] && n.left !is null) {
                recurse(n.left);
            }
            if (p[splitDimension] + r >= n.splitpoint[splitDimension] && n.right !is null) {
                recurse(n.right);
            }
        }
        recurse(root);
        return ret;
    }

    Point!Dim[] knnQuery(Point!Dim p, int k) {
        auto queue = makePriorityQueue(p);
        void recurse(size_t splitDimension, size_t Dim)(Node!splitDimension n, AABB!Dim bucket) {
            if (queue.length < k) {
                queue.insert(n.splitpoint);
            } else if (distance(p, queue.front) > distance(p, n.splitpoint)) {
                queue.popFront;
                queue.insert(n.splitpoint);
            }
            AABB!Dim leftBucket;
            leftBucket.min = bucket.min.dup;
            leftBucket.max = bucket.max.dup;
            leftBucket.max[splitDimension] = n.splitpoint[splitDimension];
            if (n.left !is null && (queue.length < k || distance(closest(leftBucket, p), p) < distance(p, queue.front))) {
                recurse(n.left, leftBucket);
            }
            AABB!Dim rightBucket;
            rightBucket.min = bucket.min.dup;
            rightBucket.max = bucket.max.dup;
            rightBucket.min[splitDimension] = n.splitpoint[splitDimension];
            if (n.right !is null && (queue.length < k || distance(closest(rightBucket, p), p) < distance(p, queue.front))) {
                recurse(n.right, rightBucket);
            }
        }
        AABB!Dim infinityBucket = AABB!Dim();
        infinityBucket.min[] = -float.infinity;
        infinityBucket.max[] = float.infinity;
        recurse(root, infinityBucket);
        return queue.release;
    }
}

unittest{
    auto pts = [Point!2([.5, .5]), Point!2([1,1]),
    Point!2([0.75, 0.4]), Point!2([0.4, 0.74])];
    auto kd_tree = KDTree!2(pts);

    writeln("kdtree range query");
    foreach(p; kd_tree.rangeQuery(Point!2([1,1]), .7)){
        writeln(p);
    }

    writeln("kdtree knn");
    foreach(p; kd_tree.knnQuery(Point!2([1,1]), 3)){
        writeln(p);
    }
}