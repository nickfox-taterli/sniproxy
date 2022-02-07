# DNS解锁定制工具

此为`半定制`工具,因此懒得写说明.

---

## 有什么功能

- [x] 使用AdGuardHome作为后端DNS管理,支持AdGuardHome所有特性,包括黑白名单广告过滤等等.
- [x] 使用SNIProxy进行后端Web代理,支持HTTP/HTTPS协议.
- [x] 支持动态更改母鸡IPv4/IPv6并自动重新加载配置文件.
- [x] 可手动编辑重写名单,支持双栈重写.
- [x] 高级功能由GNET提供,此处懒得写.
- [x] 可以设置管理密码.

---

## 怎么运行

```shell
docker run -d \
--network=host \
--restart unless-stopped \
-e PASSWORD=xxoo \
taterli/sniproxy
```

