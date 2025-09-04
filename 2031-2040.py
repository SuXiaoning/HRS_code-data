import pandas as pd
import gurobipy as gp

# 只考虑源汇相接+管道类型
# 导入数据文件名为 'parameters.xlsx'
#file_path = 'D:/study/document/博士/学习/笔记/9.毕设/毕业设计合集-除源汇匹配/第4章/数据/parameters_smallsample.xlsx'
file_path = 'D:/pythonProject/parameters_bigsample100km_19.xlsx'

# 读取Excel中的各个参数
C_s = pd.read_excel(file_path, sheet_name='C_s')['cost'].tolist()       # 碳源单位捕集成本
C_r = pd.read_excel(file_path, sheet_name='C_r')['cost'].tolist()       # 碳汇单位封存成本
Q_s = pd.read_excel(file_path, sheet_name='Q_s')['capacity'].tolist()   # 碳源捕集总量
Q_r = pd.read_excel(file_path, sheet_name='Q_r')['capacity'].tolist()   # 碳汇封存总量
#df_D_ij = pd.read_excel(file_path, sheet_name='D_ij', usecols='B:K', skiprows=0, nrows=51)   # 距离矩阵
df_D_ij = pd.read_excel(file_path, sheet_name='D_ij', usecols='B:ADK', skiprows=0, nrows=2804)   # 距离矩阵
D_ij = df_D_ij.values
F_d = pd.read_excel(file_path, sheet_name='F_d')['cost'].tolist()       # 管道单位建设成本
maxQ_d = pd.read_excel(file_path, sheet_name='maxQ_d')['flow'].tolist() # 最大流量
minQ_d = pd.read_excel(file_path, sheet_name='minQ_d')['flow'].tolist() # 最小流量


# 打印结果
print(D_ij)
print(len(D_ij[0]))

# 查看数据点的个数
print("数据点个数:", len(C_s))
print("数据点个数:", len(C_r))
print("数据点个数:", len(Q_s))
print("数据点个数:", len(Q_r))
print("数据点个数:", len(F_d))
print("数据点个数:", len(maxQ_d))
print("数据点个数:", len(minQ_d))
# 设置 S, R, D 值
S = len(C_s)  # 碳源数量
R = len(C_r)  # 碳汇数量
D = len(F_d)  # 管道类型数量

print(S, R, D)

mdl = gp.Model('CVRP')  # 起名字
# 创建1维变量数组，范围为 0 到 len(c-s) - 1, a-1
a = mdl.addVars(S, lb=0, vtype=gp.GRB.CONTINUOUS, name="a")
print(1)
b = mdl.addVars(R, lb=0, vtype=gp.GRB.CONTINUOUS, name="b")
print(2)
x = mdl.addVars(S, R, lb=0, vtype=gp.GRB.CONTINUOUS, name="x")
print(3)
y = mdl.addVars(S, R, D, lb=0, vtype=gp.GRB.BINARY, name="y")
print(4)

#exit()

mdl.addConstrs(
    (gp.quicksum(x[i, j] for j in range(R)) == a[i] for i in range(S)),
    name="mass_balance_source"
)
print(5)

mdl.addConstrs(
    (gp.quicksum(x[i, j] for i in range(S)) == b[j] for j in range(R)),
    name="mass_balance_sink"
)

mdl.addConstrs(
    (a[i] - Q_s[i] * 0.9 <= 0 for i in range(S)),
    name="capture_capacity"
)
print(6)

mdl.addConstrs(
    (b[j] - Q_r[j] <= 0 for j in range(R)),
    name="storage_capacity"
)
print(7)

mdl.addConstr(
    gp.quicksum(a[i] for i in range(S)) == 4891419810,
    name="reduction_target_sources"
)
print(8)

mdl.addConstr(
    gp.quicksum(b[j] for j in range(R)) == 4891419810,
    name="reduction_target_sinks"
)
print(9)

mdl.addConstrs(
    (x[i, j] - 10 * gp.quicksum(maxQ_d[d] * y[i, j, d] for d in range(D)) <= 0 for i in range(S) for j in range(R)),
    name="max_flow_constraint"
)
print(10)

mdl.addConstrs(
    (x[i, j] - 10 * gp.quicksum(minQ_d[d] * y[i, j, d] for d in range(D)) >= 0 for i in range(S) for j in range(R)),
    name="min_flow_constraint"
)
print(11)

mdl.addConstrs(
    (gp.quicksum(y[i, j, d] for d in range(D)) <= 1 for i in range(S) for j in range(R)),
    name="pipeline_count"
)
print(12)

scaling_factor = 1e6  # 选择一个缩放因子

# 定义目标函数
objective = (
    gp.quicksum(C_s[i] * a[i] / scaling_factor for i in range(S)) +
    gp.quicksum(1.1 * F_d[d] * y[i, j, d] * D_ij[i, j] / scaling_factor for i in range(S) for j in range(R) for d in range(D)) +
    gp.quicksum(0.02 * 1.1 * D_ij[i, j] * x[i, j] / scaling_factor for i in range(S) for j in range(R)) +
    gp.quicksum(C_r[j] * b[j] / scaling_factor for j in range(R))
)

print(13)

# 设置目标函数为最小化
mdl.setObjective(objective, gp.GRB.MINIMIZE)

max_runtime = 3600  # 设置最大运行时间为 1 小时
mdl.setParam('TimeLimit', max_runtime)
mdl.setParam('NumericFocus', 0)  # 提高数值稳定性
mdl.setParam('PreSolve', 2)      # 启用更多预处理来简化模型
# mdl.setParam('Threads', 4)       # 限制使用的线程数，避免过度消耗资源
# mdl.setParam('MIPGap', 0.1)      # 设置目标间隙，提升求解速度

print(13.1)


# 运行优化并捕获中断
try:
    mdl.optimize()
except KeyboardInterrupt:
    print("Optimization interrupted by user.")
finally:
    if mdl.solCount > 0:
        print("Feasible solution found.")
        print("Objective value:", mdl.objVal)

        # 导出 a[i]
        a_values = [a[i].x for i in range(S)]
        df_a = pd.DataFrame({'a[i]': a_values})
        df_a.to_excel('D:/pythonProject/a_values.xlsx', index=False)

        # 导出 b[j]
        b_values = [b[j].x for j in range(R)]
        df_b = pd.DataFrame({'b[j]': b_values})
        df_b.to_excel('D:/pythonProject/b_values.xlsx', index=False)

        # 导出 x[i][j]
        x_values = [[x[i, j].x for j in range(R)] for i in range(S)]
        df_x = pd.DataFrame(x_values)
        df_x.to_excel('D:/pythonProject/x_values.xlsx', index=False, header=[f'x[{j}]' for j in range(R)])

        # 导出 y[i][j][d]
        y_flat = []
        for i in range(S):
            for j in range(R):
                for d in range(D):
                    y_flat.append([i, j, d, y[i, j, d].x])
        max_rows_per_file = 1000000
        for start_row in range(0, len(y_flat), max_rows_per_file):
            end_row = min(start_row + max_rows_per_file, len(y_flat))
            y_batch = y_flat[start_row:end_row]
            df_y_batch = pd.DataFrame(y_batch, columns=['i', 'j', 'd', 'y[i][j][d]'])
            file_name = f'D:/pythonProject/y_values_batch_{start_row // max_rows_per_file + 1}.xlsx'
            df_y_batch.to_excel(file_name, index=False)
        print("All batches exported.")
    else:
        print("No feasible solution found.")