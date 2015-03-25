#!/bin/sh

scp -i ~/.ssh/hubot-aws.pem /Users/wagner/hubot/pcc/* ubuntu@hubot-aws:/home/ubuntu/hubot-pcc/
ssh -i ~/.ssh/hubot-aws.pem ubuntu@hubot-aws "rm -fr /home/ubuntu/hubot-pcc/scripts/*"
scp -i ~/.ssh/hubot-aws.pem /Users/wagner/hubot/pcc/scripts/* ubuntu@hubot-aws:/home/ubuntu/hubot-pcc/scripts/
ssh -i ~/.ssh/hubot-aws.pem ubuntu@hubot-aws "sudo service hubot-pcc restart"