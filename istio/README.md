# 如果环境不是云环境，不支持LoadBalancer
# 作如下修改，使得 ingressgateway 监听在80和443端口
# 修改使用主机端口映射
# 使用此修改版本之后，每台机器只能运行单个实例
# 大概在3027行左右