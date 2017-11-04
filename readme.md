### MySQL real-time replication to Hive

Base on documents :

```bash
https://www.packtpub.com/mapt/book/big_data_and_business_intelligence/9781788397186/10/ch10lvl1sec63/real-time-integration-with-mysql-applier
http://ylzhj02.iteye.com/blog/2164234
https://planet.mysql.com/entry/?id=47141
https://github.com/Flipkart/MySQL-replication-listener
http://innovating-technology.blogspot.com/2013/04/mysql-hadoop-applier-part-2.html
http://innovating-technology.blogspot.com/2013/04/mysql-hadoop-applier-part-2.html
http://innovating-technology.blogspot.com/2013/04/mysql-hadoop-applier-part-2.html
https://blogs.oracle.com/mysql/announcing-the-mysql-applier-for-apache-hadoop
https://github.com/linpelvis/carrygo
```

#### Step to Install

Before install we must remember some notes as below :

* Must using MySQL 5.6
* We must edit something in codes to make it works
* Tip to find JAVA_HOME `export JAVA_HOME=$(readlink -f /usr/bin/java | sed "s:bin/java::")`

Run command to create 


Start install

* `git clone git@github.com:thienkimlove/mysql_realtime_replication_hive.git /store`
* Check `Dockerfile` , we will using this to create docker for Mysql5.6 and Ubuntu 14.04

```bash
FROM ubuntu:14.04

ENV DEBIAN_FRONTEND noninteractive
ENV INITRD No
ENV LANG en_US.UTF-8
RUN apt-get update && apt-get install -y openssh-server
RUN mkdir /var/run/sshd
RUN echo 'root:tieungao' | chpasswd
RUN sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile
RUN apt-get install --no-install-recommends -y mysql-server-5.6 mysql-common libmysqld-dev libmysqlclient-dev cmake vim  build-essential default-jdk libssl-dev wget

EXPOSE 80 443 3306 22 9160 9161 9162
CMD /usr/sbin/sshd -D
``` 
* Download all needed software :

```bash
cd /store
git clone https://github.com/Flipkart/MySQL-replication-listener
mkdir temp
cd temp
wget wget http://mirror.downloadvn.com/apache/hadoop/common/hadoop-2.8.1/hadoop-2.8.1.tar.gz
tar xzvf hadoop-2.8.1.tar.gz
wget http://apache.mesi.com.ar/hive/hive-2.1.1/apache-hive-2.1.1-bin.tar.gz
tar xzvf apache-hive-2.1.1-bin.tar.gz
wget http://downloads.mysql.com/snapshots/pb/hadoop-applier/mysql-hadoop-applier-0.1.0-alpha.tar.gz
tar xzvf mysql-hadoop-applier-0.1.0-alpha.tar.gz
```
Copy configuration which we already modified to Hadoop and Hive Instance

```bash
cp -r hadoop_configuration/* hadoop-2.8.1/etc/hadoop/
cp -r hive_configuration/* apache-hive-2.1.1-bin/conf/
```

Build and start docker with MySQL 5.6
```bash
docker build -t fuck .
docker run -d --name tieungao -p 33060:3306 -v /store:/store fuck
docker exec -it tieungao
```
After go to docker instance
```bash
ln -s /store/temp/hadoop-2.8.1 /usr/local/hadoop
ln -s /store/temp/apache-hive-2.1.1-bin /usr/local/hive
```
Addition step for install Hive and Hadoop

Read more about Install Hadoop on `http://www.bogotobogo.com/Hadoop/BigData_hadoop_Install_on_ubuntu_16_04_single_node_cluster.php`
Read more about install Hive on `https://hadoop7.wordpress.com/2017/01/27/installing-hive-on-ubuntu-16-04/`

Add to `~/.bashrc`

```bash
export JAVA_HOME=/usr/lib/jvm/java-7-openjdk-amd64
export HADOOP_INSTALL=/usr/local/hadoop
export HADOOP_HOME=/usr/local/hadoop
export PATH=$PATH:$HADOOP_INSTALL/bin
export PATH=$PATH:$HADOOP_INSTALL/sbin
export HADOOP_MAPRED_HOME=$HADOOP_INSTALL
export HADOOP_COMMON_HOME=$HADOOP_INSTALL
export HADOOP_HDFS_HOME=$HADOOP_INSTALL
export YARN_HOME=$HADOOP_INSTALL
export HADOOP_COMMON_LIB_NATIVE_DIR=$HADOOP_HOME/lib/native
export HADOOP_OPTS="-Djava.library.path=$HADOOP_HOME/lib"
export HADOOP_OPTS="$HADOOP_OPTS -Djava.library.path=$HADOOP_HOME/lib/native"
#HADOOP VARIABLES END
export HIVE_HOME="/usr/local/hive"
export PATH=$PATH:$HIVE_HOME/bin
```

Addition Step to Install on Docker Server

```bash
mkdir -p /app/hadoop/tmp
mkdir -p /usr/local/hadoop_store/hdfs/namenode
mkdir -p /usr/local/hadoop_store/hdfs/datanode
hadoop namenode -format

ssh-keygen -t rsa -b 4096 -C "quan.dm@teko.vn"
cat $HOME/.ssh/id_rsa.pub >> $HOME/.ssh/authorized_keys


/usr/local/hadoop/sbin/start-dfs.sh
/usr/local/hadoop/sbin/start-yarn.sh
hdfs dfs -mkdir -p /usr/hive/warehouse
hdfs dfs -chmod 777 /usr/hive/warehouse
schematool -initSchema -dbType derby
hive -e "show databases;"
```
Start with Applier

```bash
mv mysql-hadoop-applier-0.1.0 applier
cp FindHDFS.cmake applier/MyCmake/
cd applier
rm CMakeCache.txt
cmake .
make
# if have error about MYSQL_TIME then go to src/value.cpp to comment all line related

make install
```

Build Applier

```bash
cd /store/replication/examples/mysql2hdfs
make happlier
# if have error about MYSQL_TIME then go to src/value.cpp to comment all line related

```

Get HDFS URI `hdfs getconf -confKey fs.defaultFS`

Create database on Hive
```sql
hive > create database bapi_test;
hive > use bapi_test;
hive > create table test1 (time_stamp INT, row_id INT, msg STRING) row format delimited  fields terminated by ',' stored as textfile;
mysql> set session binlog_format = 'ROW';
mysql> create database bapi_test;
mysql> use bapi_test;
mysql> create table test1 (row_id INT AUTO_INCREMENT PRIMARY KEY, msg VARCHAR(200));
```
Final command `./happlier --field-delimiter=, mysql://root@localhost hdfs://localhost:9000`

Some error may happened :

* Can connect to master

The file `/etc/my.cnf` should contain at least

```bash
#[mysqld]
#log-bin=mysqlbin-log
#binlog_format=ROW
#binlog_checksum=NONE
#server-id=2 #please note that this can be anything other than 1, since applier uses 1 to act as a slave (code in src/tcp_driver.cpp), so MySQL server cannot have the same id.
#port=3306
```
* Can not connect to HDFS

```bash
source shell/export.sh
echo $CLASSPATH >> ~/.bashrc
source ~/.bashrc

#DROP TABLE HIVE if needed
hive> DROP DATABASE IF EXISTS bapi_test CASCADE;

```
Check more at `http://ylzhj02.iteye.com/blog/2165592`

 * Restart container
  - start `/store/shell/init.sh`
  - stop `/store/shell/stop.sh`

Other Useful Commands 
```bash
hive -e "select * from bapi_test.test1"
mysql -e "insert into bapi_test.test1 (msg) values ('test1test2'), ('continues')"

/store/replication/examples/mysql2hdfs/happlier --field-delimiter=, mysql://root@localhost hdfs://localhost:9000
```