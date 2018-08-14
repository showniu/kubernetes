

## Using Admission Controllers 

我给他翻译为：许可控制器

相当于kube-apiserver的功能开关、在没有正确启用控制器的情况下，kubernetes的许多高及功能需要启用控制器才可以

开启控制器：在kube-apiserver启动参数添加`--enable-admission-plugins`配置，各个功能用`,`分割

```bash
kube-apiserver --enable-admission-plugins=NamespaceLifecyle,LimitRanger ...
```

关闭控制器：在kube-apiserver启动参数添加`--disable-admission-plugins`配置

```bash
kube-apiserver --disable-admission-plugins=PodNodeSelector,AlwaysDeny ...
```



###控制器有很多`Admission`，每个`Admission`功能不同

详情看这里：https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/