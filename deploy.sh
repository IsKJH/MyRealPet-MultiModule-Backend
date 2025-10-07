#!/bin/bash

# MyRealPet Deployment Script
# This script runs on EC2 server

APP_DIR="/home/ubuntu/app"
LOG_DIR="/home/ubuntu/app/logs"

# Create log directory if not exists
mkdir -p $LOG_DIR

echo "[$(date)] Starting deployment..." >> $LOG_DIR/deploy.log

# Stop existing applications
echo "[$(date)] Stopping existing applications..." >> $LOG_DIR/deploy.log
pkill -f 'account.*jar' || true
pkill -f 'pet-walk.*jar' || true

# Wait for ports to be released
sleep 5

# Start Account API
echo "[$(date)] Starting Account API..." >> $LOG_DIR/deploy.log
cd $APP_DIR
nohup java -jar \
  -Dspring.profiles.active=prod \
  -DACCOUNT_DB_URL="${ACCOUNT_DB_URL}" \
  -DACCOUNT_DB_USERNAME="${ACCOUNT_DB_USERNAME}" \
  -DACCOUNT_DB_PASSWORD="${ACCOUNT_DB_PASSWORD}" \
  -DREDIS_HOST="${REDIS_HOST}" \
  -DREDIS_PORT="${REDIS_PORT}" \
  -DREDIS_PASSWORD="${REDIS_PASSWORD}" \
  -DCORS_ALLOWED_ORIGINS="${CORS_ALLOWED_ORIGINS}" \
  account-api*.jar > $LOG_DIR/account.log 2>&1 &

ACCOUNT_PID=$!
echo "[$(date)] Account API started with PID: $ACCOUNT_PID" >> $LOG_DIR/deploy.log

# Start Pet-Walk API
echo "[$(date)] Starting Pet-Walk API..." >> $LOG_DIR/deploy.log
nohup java -jar \
  -Dspring.profiles.active=prod \
  -DPET_WALK_DB_URL="${PET_WALK_DB_URL}" \
  -DPET_WALK_DB_USERNAME="${PET_WALK_DB_USERNAME}" \
  -DPET_WALK_DB_PASSWORD="${PET_WALK_DB_PASSWORD}" \
  pet-walk-api*.jar > $LOG_DIR/pet-walk.log 2>&1 &

PET_WALK_PID=$!
echo "[$(date)] Pet-Walk API started with PID: $PET_WALK_PID" >> $LOG_DIR/deploy.log

# Wait a moment for applications to start
sleep 3

# Check if processes are running
if ps -p $ACCOUNT_PID > /dev/null; then
   echo "[$(date)] Account API is running successfully" >> $LOG_DIR/deploy.log
else
   echo "[$(date)] ERROR: Account API failed to start" >> $LOG_DIR/deploy.log
fi

if ps -p $PET_WALK_PID > /dev/null; then
   echo "[$(date)] Pet-Walk API is running successfully" >> $LOG_DIR/deploy.log
else
   echo "[$(date)] ERROR: Pet-Walk API failed to start" >> $LOG_DIR/deploy.log
fi

echo "[$(date)] Deployment completed!" >> $LOG_DIR/deploy.log
