check_redshift_free_storage_space
========================================

Nagios plugin for Amazon Redshift free space check.

# How to setup

1) If you use CentOS install postgresql-devel.
```
# yum -y install postgresql-devel
```


2) Install gem library.
```
# bundle
```

3) Run script.
```
# ruby check_redshift_free_storage_space.rb -H xxxxx.ap-northeast-1.redshift.amazonaws.com -P 5439 -d my_database -u my_user -p my_password -w 50% -c 80%
OK - total: 7168GB, used: 2048GB (28%), free: 5120GB (72%)|used=2048
```

# License

Streem is distributed under MIT license.

Takeshi Yako
