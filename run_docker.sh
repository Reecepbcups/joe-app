VERSION=0.0.1

docker build -t reecepbcups/justjoe-app:$VERSION .
docker run --rm --name=justjoe-app -p 6001:6001 reecepbcups/justjoe-app:$VERSION